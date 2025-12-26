#!/bin/bash
# Setup script for Coqui TTS Server

set -e

echo "🐸 Setting up Coqui TTS Server..."

# Find compatible Python (3.9-3.11)
PYTHON_CMD=""
for py in python3.11 python3.10 python3.9; do
    if command -v $py &> /dev/null; then
        PYTHON_CMD=$py
        break
    fi
done

# Check Homebrew paths if not found
if [ -z "$PYTHON_CMD" ]; then
    for py in /opt/homebrew/bin/python3.11 /opt/homebrew/bin/python3.10 /opt/homebrew/bin/python3.9; do
        if [ -x "$py" ]; then
            PYTHON_CMD=$py
            break
        fi
    done
fi

if [ -z "$PYTHON_CMD" ]; then
    echo "❌ Error: Python 3.9-3.11 is required but not found."
    echo "Please install Python 3.11: brew install python@3.11"
    exit 1
fi

python_version=$($PYTHON_CMD --version 2>&1 | cut -d' ' -f2)
echo "Using Python: $PYTHON_CMD (version $python_version)"

# Remove old venv if exists (might be wrong Python version)
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# Create virtual environment
echo "Creating virtual environment..."
$PYTHON_CMD -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
echo "Installing dependencies..."
pip install -r requirements.txt

# Download a default model
echo "Downloading default TTS model..."
python3 -c "from TTS.api import TTS; TTS('tts_models/en/ljspeech/tacotron2-DDC')"

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the server, run:"
echo "  source venv/bin/activate"
echo "  python server.py"
echo ""
echo "Or with a specific model:"
echo "  python server.py --model_name tts_models/en/vctk/vits"
