"""LiteLLM callback that forces temperature=1 for Moonshot kimi models."""
import litellm
from litellm.integrations.custom_logger import CustomLogger
from litellm.proxy.proxy_server import UserAPIKeyAuth
from typing import Optional, Literal

class ForceTempOne(CustomLogger):
    async def async_pre_call_hook(
        self, data: dict, user_api_key_dict: UserAPIKeyAuth, **kwargs
    ):
        # data contains {"model": ..., "messages": ...}
        model = data.get("model", "")
        if "kimi" in model.lower():
            data["temperature"] = 1.0
            data["max_tokens"] = data.get("max_tokens", 8192)
        return data

proxy_instance = ForceTempOne()
