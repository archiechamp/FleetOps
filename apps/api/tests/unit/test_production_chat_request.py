"""Compatibility checks for the AI SDK chat request envelope."""

from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.modules.ai.production_routes import ChatRequest


def test_chat_request_accepts_submit_trigger() -> None:
    request = ChatRequest.model_validate(
        {
            "id": str(uuid4()),
            "messages": [
                {
                    "id": str(uuid4()),
                    "role": "user",
                    "parts": [{"type": "text", "text": "What vehicles are in my fleet?"}],
                }
            ],
            "trigger": "submit-message",
        }
    )

    assert request.trigger == "submit-message"


def test_chat_request_still_rejects_unexpected_fields() -> None:
    with pytest.raises(ValidationError):
        ChatRequest.model_validate(
            {"id": str(uuid4()), "messages": [{"role": "user"}], "tenant_id": str(uuid4())}
        )
