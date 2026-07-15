from fastapi import APIRouter, Response, Request, status
import logging
from app.model import AgentRequest

logger = logging.getLogger("ai-aegis-platform")
