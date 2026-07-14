from fastapi import APIRouter, Response, Request, status
import logging
from app.model import AgentRequest

logger = logging.getLogger("ai-aegis-platform")

router = APIRouter()

@router.post("/run")
async def agent_task_async(body: AgentRequest, response: Response, request: Request):
    client: "AsyncOpenAI" = getattr(request.app.state, "openai_client", None)

    settings = getattr(request.app.state, "_settings", None)
    if client is None and settings is None:
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"error": "OpenAI client or settings not configured."}
    
    if not settings.model_deployment_name:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        return {
            "error": "Model deployment not configured. Set LLM_MODEL_DEPLOYMENT_NAME."
        }
    
    try:
        completion = await client.chat.completions.create(
            model=settings.model_deployment_name,
            messages=[
                {"role": "system", "content": "You are a compact Agent."},
                {"role": "user", "content": body.prompt},
            ],
        )

        return {
            "user_prompt": body.prompt,
            "agent_response": completion.choices[0].message.content,
        }
    except Exception as e:
        logger.error(f"Execution failure calling OpenAI layer: {e}")
        response.status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        return {"error": "Failed to communicate with LLM engine.", "details": str(e)}