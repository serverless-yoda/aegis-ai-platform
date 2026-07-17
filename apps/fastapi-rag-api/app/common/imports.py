import logging

from fastapi import FastAPI, APIRouter, Response, Request, status
from app.model import AgentRequest
from contextlib import asynccontextmanager
from openai import AsyncOpenAI


logger = logging.getLogger("ai-aegis-platform")
