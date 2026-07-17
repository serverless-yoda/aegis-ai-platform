from common.imports import *

from app.config import Settings
from app.api import register_routers

logging.basicConfig(level=logging.INFO, format="%(levelname)s: [%(name)s] %(message)s")
logger = logging.getLogger("ai-aegis-platform")

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info('Container booting and initializing infrastructure...')
    settings = Settings()
    app.state._settings = settings
    app.state.openai_client = None

    if settings.azure_openai_endpoint and settings.model_deployment_name:
        logger.info('Initializing AsyncOpenAI client with provided configuration...')
        app.state.openai_client = AsyncOpenAI(
            base_url=settings.azure_openai_endpoint,
            api_key=settings.azure_openai_api_key,
        )
        logger.info('✓ AsyncOpenAI client successfully initialized.')
    else:
        logger.error('❌ Upstream configuration missing. Application state: UNREADY.')
    
    yield

    if getattr(app.state, "openai_client", None):
        await app.state.openai_client.close()
    
    logger.info('Container shutting down context cleanly.')


def create_app() -> FastAPI:
    app = FastAPI(
        lifespan=lifespan,
        description="Unified API for AI Agent and RAG services.",
        title="Azure Agentic AI")
    register_routers(app)
    return app

app = create_app()
