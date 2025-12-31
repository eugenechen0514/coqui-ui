import wave
import audioop
import sys

def analyze_wav(filename):
    try:
        with wave.open(filename, 'rb') as wav_file:
            n_channels = wav_file.getnchannels()
            sample_width = wav_file.getsampwidth()
            frame_rate = wav_file.getframerate()
            n_frames = wav_file.getnframes()
            
            print(f"File: {filename}")
            print(f"Channels: {n_channels}")
            print(f"Sample Width: {sample_width}")
            print(f"Frame Rate: {frame_rate}")
            print(f"Frames: {n_frames}")
            
            raw_data = wav_file.readframes(n_frames)
            rms = audioop.rms(raw_data, sample_width)
            max_val = audioop.max(raw_data, sample_width)
            
            print(f"RMS Amplitude: {rms}")
            print(f"Max Amplitude: {max_val}")
            
            if rms == 0:
                print("WARNING: Audio is completely silent.")
            else:
                print("Audio appears to have content.")
            print("-" * 20)
            
    except Exception as e:
        print(f"Error analyzing {filename}: {e}")

if __name__ == "__main__":
    for f in sys.argv[1:]:
        analyze_wav(f)
