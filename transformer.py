import os
import httpx
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

_http_client = httpx.Client(transport=httpx.HTTPTransport())

_client = OpenAI(
    base_url=os.environ["LLM_URL"],
    api_key=os.environ["LLM_TOKEN"],
    http_client=_http_client,
)

SYSTEM_PROMPT = """Ты — помощник для деловой переписки с коллегами.
Твоя задача: переформулировать переданный текст, соблюдая правила:
- Тон дружелюбный и профессиональный, но не официальный. Обращение на «ты».
- Слово «коллеги» не использовать никогда.
- Исправляй опечатки, орфографию и пунктуацию.
- Никогда не используй длинное тире (символ —). Это запрет без исключений. Перефразируй предложение или используй двоеточие, запятую, скобки.
- Если в тексте есть перечисления — оформляй их буллетами (- пункт), не нумерацией.
- Сохраняй смысл и факты оригинала.
- Отвечай только исправленным текстом, без пояснений и комментариев."""


def transform(text: str) -> str:
    """Преобразует текст в деловой стиль через LLM."""
    response = _client.chat.completions.create(
        model=os.environ["LLM_MODEL"],
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": text},
        ],
        temperature=0.3,
    )
    result = response.choices[0].message.content.strip()
    result = result.replace("—", "-")
    result = result.translate(str.maketrans("ёЁ", "еЕ"))
    return result
