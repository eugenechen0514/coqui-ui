# CoquiUI - macOS Text-to-Speech App

A native macOS application built with SwiftUI that provides a beautiful interface for [Coqui TTS](https://github.com/coqui-ai/TTS), an open-source text-to-speech engine.

## Features

- 🎙️ **Text-to-Speech Synthesis** - Convert text to natural-sounding speech
- 🗣️ **Voice Cloning** - Clone voices using reference audio (with XTTS model)
- 🌍 **Multi-language Support** - Support for 16+ languages
- 📚 **Model Management** - Browse and switch between different TTS models
- 🎛️ **Voice Settings** - Adjust speed, select speakers, and configure output
- 📜 **Audio History** - Keep track of previously synthesized audio
- 🖥️ **Native macOS UI** - Beautiful SwiftUI interface with dark mode support

## Architecture

```
CoquiUI/
├── CoquiUI/                    # Swift macOS App (SwiftUI)
│   └── Sources/
│       ├── App/               # App entry point
│       ├── Models/            # Data models
│       ├── Services/          # TTS service, audio player
│       ├── ViewModels/        # MVVM view models
│       └── Views/             # SwiftUI views
└── CoquiTTSServer/            # Python TTS Server
    ├── server.py              # Flask REST API
    ├── requirements.txt       # Python dependencies
    └── setup.sh               # Setup script
```

## Requirements

### macOS App
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

### TTS Server
- Python 3.9 or later
- 4GB+ RAM (8GB+ recommended for larger models)
- GPU with CUDA support (optional, for faster synthesis)

## Quick Start

### 1. Setup the TTS Server

```bash
cd CoquiTTSServer

# Run the setup script
./setup.sh

# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Start the Server

```bash
cd CoquiTTSServer
source venv/bin/activate

# Start with default model
python server.py

# Or specify a model
python server.py --model_name tts_models/en/vctk/vits --port 5002
```

### 3. Build and Run the macOS App

```bash
cd CoquiUI

# Using Swift Package Manager
swift build
swift run

# Or open in Xcode
open Package.swift
```

## Available Models

### Recommended Models

| Model | Language | Type | Notes |
|-------|----------|------|-------|
| `tts_models/en/ljspeech/tacotron2-DDC` | English | Single Speaker | Fast, good quality |
| `tts_models/en/vctk/vits` | English | Multi-Speaker | 109 speakers |
| `tts_models/multilingual/multi-dataset/xtts_v2` | Multi | Voice Cloning | 16 languages, clone any voice |

### List All Models

```bash
tts --list_models
```

## API Endpoints

The Python server exposes the following REST endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/api/tts` | GET/POST | Synthesize speech |
| `/api/models` | GET | List available models |
| `/api/speakers` | GET | List speakers for current model |
| `/api/languages` | GET | List languages for current model |
| `/api/model` | POST | Change current model |

### Example: Synthesize Speech

```bash
# GET request
curl "http://localhost:5002/api/tts?text=Hello%20world" --output hello.wav

# POST request with voice cloning
curl -X POST "http://localhost:5002/api/tts" \
  -F "text=Hello world" \
  -F "language_id=en" \
  -F "speaker_wav=@reference.wav" \
  --output cloned.wav
```

## Configuration

### App Settings

Access settings via **CoquiUI > Settings** or `⌘,`:

- **Python Path**: Path to your Python installation
- **Server Port**: Default 5002
- **Default Model**: Model to load on server start
- **Auto-start Server**: Start server when app launches
- **Output Directory**: Where to save audio files

### Server Options

```bash
python server.py --help

Options:
  --port        Server port (default: 5002)
  --host        Server host (default: 0.0.0.0)
  --model_name  Initial TTS model to load
  --debug       Enable debug mode
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘↵` | Synthesize |
| `⌘⇧S` | Start Server |
| `⌘⇧Q` | Stop Server |
| `⌘R` | Refresh Models |
| `⌘,` | Settings |

## Troubleshooting

### Server won't start

1. Check Python path in Settings
2. Verify TTS is installed: `pip show TTS`
3. Check server logs in the Logs tab

### No audio output

1. Ensure server is running (green indicator)
2. Check system audio settings
3. Try a different model

### Slow synthesis

1. Use a simpler model (e.g., Tacotron2 instead of XTTS)
2. Enable GPU acceleration if available
3. Reduce text length

## License

This project is open source. The Coqui TTS library is licensed under MPL-2.0.

## Credits

- [Coqui TTS](https://github.com/coqui-ai/TTS) - The amazing open-source TTS engine
- Built with SwiftUI for macOS
