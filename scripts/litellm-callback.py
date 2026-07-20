"""LiteLLM callback that forces temperature=1 for kimi models."""
import litellm
from litellm.integrations.custom_logger import CustomLogger
from typing import Any

class ForceTempOne(CustomLogger):
    def log_pre_api_call(self, model, messages, kwargs):
        # Called BEFORE the upstream API request
        if "kimi" in (model or "").lower():
            kwargs["temperature"] = 1.0
            kwargs.setdefault("max_tokens", 8192)
        return kwargs

    def log_success_event(self, kwargs, response_obj, start_time, end_time):
        pass

    def log_failure_event(self, kwargs, response_obj, start_time, end_time):
        pass
