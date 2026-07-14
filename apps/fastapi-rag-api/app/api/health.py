from fastapi import APIRouter, Response, Request, status
import logging

logger = logging.getLogger("ai-aegis-platform")
router = APIRouter()

is_healthy = True

@router.get("/health/live")
async def liveness_probe_async(response: Response):
    if is_healthy:
        return {"status": "alive"}
    
    logger.error(
        "Liveness probe failed! Triggering container orchestration restart sequence."
    )
    response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    return {"status": "unhealthy", "reason": "simulated_deadlock"}


@router.get("/health/ready")
async def readiness_probe_async(response: Response, request: Request):
    client = getattr(request.app.state, "openai_client", None)

    if not client:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not_ready", "reason": "endpoint_or_credentials_missing"}
    
    if not is_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {"status": "not_ready", "reason": "system_is_not_ready"}
    
    return {"status": "ready"}
