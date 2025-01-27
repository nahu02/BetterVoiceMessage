import os

import openai
from dotenv import load_dotenv

load_dotenv()

OPENWEBUI_CLIENT = openai.Client(
    base_url=os.getenv("OPENWEBUI_BASE_URL"), api_key=os.getenv("OPENWEBUI_API_KEY")
)
