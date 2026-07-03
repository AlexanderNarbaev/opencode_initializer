import asyncio
import json
from aiohttp import web
import aiohttp

OLLAMA_URL = "http://localhost:11434"

async def handle_embed(request):
    try:
        data = await request.json()
        texts = data.get("texts", data.get("input", []))
        if isinstance(texts, str):
            texts = [texts]

        async with aiohttp.ClientSession() as session:
            async with session.post(
                f"{OLLAMA_URL}/api/embed",
                json={"model": "mxbai-embed-large", "input": texts}
            ) as resp:
                result = await resp.json()
                embeddings = result.get("embeddings", [])
                data = [{"index": i, "embedding": emb} for i, emb in enumerate(embeddings)]
                return web.json_response({
                    "object": "list",
                    "data": data,
                    "model": "mxbai-embed-large"
                })
    except Exception as e:
        return web.json_response({"error": str(e)}, status=500)

async def handle_health(request):
    return web.json_response({"status": "healthy"})

app = web.Application()
app.router.add_post("/v1/embeddings", handle_embed)
app.router.add_post("/embed", handle_embed)
app.router.add_get("/health", handle_health)
app.router.add_get("/", handle_health)

if __name__ == "__main__":
    web.run_app(app, host="127.0.0.1", port=61051)
