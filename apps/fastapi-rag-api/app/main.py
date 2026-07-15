import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from openai import AsyncOpenAI
from app.config import Settings
from app.api import register_routers

logging.basicConfig(level=logging.INFO, format="%(levelname)s: [%(name)s] %(message)s")
logger = logging.getLogger("ai-aegis-platform")