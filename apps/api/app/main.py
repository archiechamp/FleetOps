from fastapi import FastAPI, HTTPException
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()
    if settings.env == "demo":
        if not settings.demo_session_secret or len(settings.demo_session_secret) < 32:
            raise RuntimeError("Demo session secret must be set and at least 32 characters")
        if not settings.demo_runtime_password:
            raise RuntimeError("Demo runtime SQL password is required")
    app = FastAPI(title="FleetOps API", version="0.1.0")

    if settings.env == "demo":
        from app.core.demo_auth import router as demo_router
        from app.modules.ai.routes import router as ai_router
        from app.modules.demo_operations.routes import router as demo_operations_router
        from app.modules.fleet.routes import router as fleet_router
        app.include_router(demo_router, prefix="/api/v1")
        app.include_router(fleet_router, prefix="/api/v1")
        app.include_router(demo_operations_router, prefix="/api/v1")
        app.include_router(ai_router, prefix="/api/v1")

    @app.get("/health/live", tags=["health"])
    def live() -> dict[str, str]:
        return {"status": "live"}

    @app.get("/health/ready", tags=["health"])
    def ready() -> dict[str, str]:
        if settings.env == "demo":
            from app.core.demo_db import engine
            try:
                with engine.connect() as connection:
                    revision = connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one()
                if revision == "0005_demo_ai_chat":
                    return {"status": "ready"}
            except SQLAlchemyError:
                raise HTTPException(status_code=503, detail="Service is not ready") from None
        raise HTTPException(status_code=503, detail="Service is not ready")

    return app


app = create_app()
