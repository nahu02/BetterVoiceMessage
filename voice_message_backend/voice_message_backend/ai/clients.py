import os

import openai
from dotenv import load_dotenv

load_dotenv()

OPENWEBUI_CLIENT = openai.Client(
    base_url=os.getenv("OPENWEBUI_BASE_URL"), api_key=os.getenv("OPENWEBUI_API_KEY")
)

PERPLEXITY_CLIENT = openai.Client(
    base_url="https://api.perplexity.ai",
    api_key=os.getenv("PERPLEXITY_API_KEY", "YOUR_PERPLEXITY_API_KEY"),
)
