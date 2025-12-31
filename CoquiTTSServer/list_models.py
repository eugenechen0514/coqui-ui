from TTS.api import TTS
try:
    models = TTS().list_models().list_models()
    print("Found models:", len(models))
    for m in models:
        if 'zh' in m or 'chinese' in m or 'multilingual' in m:
            print(m)
except Exception as e:
    print(e)
