from fastapi import FastAPI
import uvicorn

app = FastAPI()


@app.get("/")
async def main_route():
    return {"message": "Hello world!"}


def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)
