import os
from pydantic_settings import BaseSettings

logger = logging.getLogger("ai-aegis-platform")
class Settings(BaseSettings):
    model_config = {"protected_namespaces": ()}

    azure_openai_endpoint: str = os.getenv("AZURE_OPENAI_ENDPOINT", "")
    azure_openai_api_key: str = os.getenv("AZURE_OPENAI_API_KEY", "")
    model_deployment_name: str = os.getenv("LLM_MODEL_DEPLOYMENT_NAME", "")
    max_tokens: int = int(os.getenv("LLM_MAX_TOKENS", "150"))
    temperature: float = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    top_p: float = float(os.getenv("LLM_TOP_P", "0.9"))