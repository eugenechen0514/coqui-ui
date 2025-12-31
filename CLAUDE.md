# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Project Overview

CoquiUI is a native macOS application built with SwiftUI that provides a beautiful interface for [Coqui TTS](https://github.com/coqui-ai/TTS), an open-source text-to-speech engine.

### Architecture

```
coqui-ui/
├── CoquiUI/                    # Swift Package (macOS App)
│   ├── Package.swift           # Swift 5.9, macOS 14.0+
│   └── Sources/
│       ├── Models/             # Data models (TTSModel.swift)
│       ├── Services/           # TTS service layer (TTSService.swift)
│       ├── ViewModels/         # MVVM view models (TTSViewModel.swift)
│       └── Views/              # SwiftUI views
├── CoquiUIApp/                 # Xcode project wrapper
│   └── CoquiUIApp.xcodeproj
└── CoquiTTSServer/             # Python Flask REST API
    ├── server.py               # Main server with TTS endpoints
    ├── requirements.txt        # Python dependencies
    └── setup.sh                # Setup script
```

### Key Features
- Text-to-Speech synthesis via Coqui TTS
- Voice cloning with XTTS model
- Multi-language support (16+ languages)
- Model management and switching
- Audio history tracking

## Development Commands

### Swift (macOS App)

```bash
# Build the app
cd CoquiUI && swift build

# Run the app
cd CoquiUI && swift run

# Open in Xcode
open CoquiUI/Package.swift
```

### Python (TTS Server)

```bash
# Setup virtual environment
cd CoquiTTSServer
./setup.sh
# Or manually:
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run server
source venv/bin/activate
python server.py

# Run with specific model
python server.py --model_name tts_models/en/vctk/vits --port 5002
```

### Testing

Always run tests before committing:
- Swift: `cd CoquiUI && swift test`
- Python: `cd CoquiTTSServer && python -m pytest`

## API Endpoints (TTS Server)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/api/tts` | GET/POST | Synthesize speech |
| `/api/models` | GET | List available models |
| `/api/speakers` | GET | List speakers for current model |
| `/api/languages` | GET | List supported languages |
| `/api/model` | POST | Change current model |

### Example API Usage

```bash
# Synthesize speech
curl "http://localhost:5002/api/tts?text=Hello%20world" --output hello.wav

# Voice cloning
curl -X POST "http://localhost:5002/api/tts" \
  -F "text=Hello world" \
  -F "language_id=en" \
  -F "speaker_wav=@reference.wav" \
  --output cloned.wav
```

## Code Style

### Swift
- Follow Apple's Swift API Design Guidelines
- Use MVVM architecture pattern
- Prefer `async/await` for asynchronous operations
- Use SwiftUI for all UI components

### Python
- Follow PEP 8 style guide
- Use type hints where practical
- Use Flask for REST API endpoints

## Important Notes

- Server default port: 5002
- Requires Python 3.9+, macOS 14.0+
- GPU with CUDA optional (CPU fallback available)
- ffmpeg required for audio format conversion (voice cloning)
