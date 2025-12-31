from TTS.api import TTS
import sys

def download_xtts():
    model_name = "tts_models/multilingual/multi-dataset/xtts_v2"
    print(f"Starting download for {model_name}...")
    print("Note: You may be prompted to agree to the Coqui CPML license.")
    
    try:
        # Initializing TTS with the model name triggers download if not cached
        TTS(model_name)
        print("Model downloaded successfully!")
    except Exception as e:
        print(f"Error downloading model: {e}")
        sys.exit(1)

if __name__ == "__main__":
    download_xtts()
