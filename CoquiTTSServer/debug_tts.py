from TTS.api import TTS
print("Type of TTS().list_models():", type(TTS().list_models()))
try:
    print("Models:", TTS().list_models())
except Exception as e:
    print("Error listing models:", e)

mm = TTS().list_models()
if hasattr(mm, 'list_models'):
    print("ModelManager has list_models:", mm.list_models())
