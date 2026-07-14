from .health import router as health_router
from .agent import router as agent_router

def register_routers(app):
    app.include_router(health_router, tags=["Health"])  
    app.include_router(agent_router, tags=["Agent"])