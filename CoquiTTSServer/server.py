#!/usr/bin/env python3
"""
Coqui TTS Server - A simple REST API wrapper for Coqui TTS
This server provides endpoints for text-to-speech synthesis with voice cloning support.
"""

import argparse
import io
import json
import logging
import os
import tempfile
from pathlib import Path

from flask import Flask, request, send_file, jsonify
from flask_cors import CORS

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Global TTS instance
tts = None
current_model = None


def load_model(model_name: str):
    """Load a TTS model."""
    global tts, current_model

    try:
        from TTS.api import TTS

        logger.info(f"Loading model: {model_name}")

        # Check if CUDA is available
        import torch
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {device}")

        tts = TTS(model_name).to(device)
        current_model = model_name

        logger.info(f"Model loaded successfully: {model_name}")
        return True

    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        return False


@app.route('/')
def index():
    """Health check endpoint."""
    return jsonify({
        "status": "running",
        "model": current_model,
        "endpoints": {
            "tts": "/api/tts",
            "models": "/api/models",
            "speakers": "/api/speakers",
            "languages": "/api/languages"
        }
    })


@app.route('/api/tts', methods=['GET', 'POST'])
def synthesize():
    """Synthesize speech from text."""
    global tts

    if tts is None:
        return jsonify({"error": "No model loaded"}), 500

    try:
        # Get parameters from request
        if request.method == 'POST':
            if request.content_type and 'multipart/form-data' in request.content_type:
                text = request.form.get('text', '')
                speaker_id = request.form.get('speaker_id')
                language_id = request.form.get('language_id', 'en')
                speed = float(request.form.get('speed', 1.0))
                speaker_wav = request.files.get('speaker_wav')
            else:
                data = request.get_json() or {}
                text = data.get('text', '')
                speaker_id = data.get('speaker_id')
                language_id = data.get('language_id', 'en')
                speed = float(data.get('speed', 1.0))
                speaker_wav = None
        else:
            text = request.args.get('text', '')
            speaker_id = request.args.get('speaker_id')
            language_id = request.args.get('language_id', 'en')
            speed = float(request.args.get('speed', 1.0))
            speaker_wav = None

        if not text:
            return jsonify({"error": "No text provided"}), 400

        logger.info(f"Synthesizing: '{text[:50]}...' with language={language_id}")

        # Create temporary file for output
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp_file:
            output_path = tmp_file.name

        # Handle voice cloning with speaker_wav
        if speaker_wav:
            # Save uploaded file temporarily
            suffix = '.wav'
            if speaker_wav.filename:
                _, ext = os.path.splitext(speaker_wav.filename)
                if ext:
                    suffix = ext

            with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as ref_file:
                speaker_wav.save(ref_file.name)
                ref_path = ref_file.name

            # Convert non-wav files to wav using ffmpeg
            if suffix.lower() != '.wav':
                wav_ref_path = ref_path.replace(suffix, '.wav')
                import subprocess
                try:
                    result = subprocess.run(
                        ['ffmpeg', '-y', '-i', ref_path, '-ar', '22050', '-ac', '1', wav_ref_path],
                        capture_output=True,
                        text=True
                    )
                    if result.returncode != 0:
                        logger.error(f"ffmpeg conversion failed: {result.stderr}")
                        return jsonify({"error": f"Audio format conversion failed: {result.stderr}"}), 500
                    os.unlink(ref_path)  # Remove original
                    ref_path = wav_ref_path  # Use converted file
                except FileNotFoundError:
                    os.unlink(ref_path)
                    return jsonify({"error": "ffmpeg not found. Please install ffmpeg for audio format conversion."}), 500

            try:
                tts.tts_to_file(
                    text=text,
                    speaker_wav=ref_path,
                    language=language_id,
                    file_path=output_path
                )
            finally:
                os.unlink(ref_path)
        else:
            # Standard synthesis
            kwargs = {
                "text": text,
                "file_path": output_path
            }

            # Add optional parameters if supported by the model
            if hasattr(tts, 'speakers') and tts.speakers and speaker_id:
                kwargs["speaker"] = speaker_id

            if hasattr(tts, 'languages') and tts.languages and language_id:
                kwargs["language"] = language_id

            tts.tts_to_file(**kwargs)

        # Read and return the audio file
        with open(output_path, 'rb') as f:
            audio_data = f.read()

        os.unlink(output_path)

        return send_file(
            io.BytesIO(audio_data),
            mimetype='audio/wav',
            as_attachment=False
        )

    except Exception as e:
        logger.error(f"Synthesis error: {e}")
        return jsonify({"error": str(e)}), 500


@app.route('/api/models', methods=['GET'])
def get_models():
    """Get list of available models."""
    try:
        from TTS.api import TTS

        # Get all available models
        models = TTS().list_models()
        if not isinstance(models, list):
             models = models.list_models()

        # Filter to show only TTS models
        tts_models = [m for m in models if m.startswith('tts_models')]

        return jsonify(tts_models)

    except Exception as e:
        logger.error(f"Error getting models: {e}")
        return jsonify([]), 500


@app.route('/api/speakers', methods=['GET'])
def get_speakers():
    """Get list of available speakers for the current model."""
    global tts

    if tts is None:
        return jsonify([])

    try:
        if hasattr(tts, 'speakers') and tts.speakers:
            return jsonify(tts.speakers)
        return jsonify([])

    except Exception as e:
        logger.error(f"Error getting speakers: {e}")
        return jsonify([])


@app.route('/api/languages', methods=['GET'])
def get_languages():
    """Get list of available languages for the current model."""
    global tts

    if tts is None:
        return jsonify([])

    try:
        if hasattr(tts, 'languages') and tts.languages:
            return jsonify(tts.languages)
        return jsonify([])

    except Exception as e:
        logger.error(f"Error getting languages: {e}")
        return jsonify([])


@app.route('/api/model', methods=['POST'])
def change_model():
    """Change the current model."""
    data = request.get_json() or {}
    model_name = data.get('model_name')

    if not model_name:
        return jsonify({"error": "No model name provided"}), 400

    if load_model(model_name):
        return jsonify({"status": "success", "model": model_name})
    else:
        return jsonify({"error": "Failed to load model"}), 500


def main():
    parser = argparse.ArgumentParser(description='Coqui TTS Server')
    parser.add_argument('--port', type=int, default=5002, help='Server port')
    parser.add_argument('--host', type=str, default='0.0.0.0', help='Server host')
    parser.add_argument('--model_name', type=str,
                        default='tts_models/en/ljspeech/tacotron2-DDC',
                        help='TTS model to load')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')

    args = parser.parse_args()

    # Load initial model
    if not load_model(args.model_name):
        logger.error("Failed to load initial model. Server will start without a model.")

    # Start server
    logger.info(f"Starting server on {args.host}:{args.port}")
    app.run(host=args.host, port=args.port, debug=args.debug, threaded=True)


if __name__ == '__main__':
    main()
