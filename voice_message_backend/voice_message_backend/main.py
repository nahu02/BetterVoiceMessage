from fastapi import FastAPI
import uvicorn
from voice_message_backend.ai.messageProcessing import (
    turn_transcription_into_text_message,
)

app = FastAPI()


@app.get("/processed_voice_message")
def processed_voice_message(transcription: str, language: str):
    message = turn_transcription_into_text_message(transcription, language)

    return {"message": message}


def main():
    uvicorn.run("voice_message_backend.main:app", host="0.0.0.0", port=8000)


def run_dev():
    uvicorn.run(
        "voice_message_backend.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
    )


if __name__ == "__main__":
    run_dev()
