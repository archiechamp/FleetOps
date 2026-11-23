from functools import lru_cache
from typing import Literal

from pydantic import Field, SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="FLEETOPS_", extra="ignore")

    env: Literal["development", "test", "demo", "production"] = "development"
    database_name: str = "fleetops_dev"
    sql_server: str = "sqlserver"
    sql_encrypt: bool = True
    sql_trust_server_certificate: bool = False
    clerk_issuer: str | None = None
    clerk_authorized_party: str | None = None
    clerk_secret_key: SecretStr | None = None
    clerk_jwt_key: SecretStr | None = None
    sql_runtime_user: str | None = None
    sql_runtime_password: SecretStr | None = None
    demo_session_secret: str | None = None
    demo_runtime_password: str | None = None
    ai_provider: Literal["openai"] = "openai"
    ai_model: str = "gpt-5.4-mini"
    openai_api_key: SecretStr | None = Field(default=None, validation_alias="OPENAI_API_KEY")


@lru_cache
def get_settings() -> Settings:
    return Settings()
