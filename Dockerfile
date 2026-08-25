FROM node:24-bookworm-slim AS frontend
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

FROM ghcr.io/astral-sh/uv:0.12.5@sha256:e85be844203885286c60ffad8a858d48afb6c5a5c237ca0e67f12e74b8f174b1 AS uv

FROM python:3.11-slim-bookworm@sha256:0bee7276f83efd4a1ee05bbbf4281d95ed28e079220a9457f25a93e3f1e3c31b
COPY --from=uv /uv /uvx /bin/
ENV PYTHONUNBUFFERED=1 PYTHONPATH=/app/backend AIRL_STATIC_DIR=/app/frontend/dist DATABASE_URL=sqlite:////data/ai_readiness_lab.db
RUN useradd --create-home --uid 10001 airl
WORKDIR /app
COPY backend/requirements.txt ./backend/requirements.txt
RUN uv venv /app/.venv && uv pip install --python /app/.venv/bin/python --requirement backend/requirements.txt
COPY backend/ ./backend/
COPY --from=frontend /app/frontend/dist ./frontend/dist
RUN mkdir -p /data && chown -R airl:airl /app /data
USER airl
ENV PATH="/app/.venv/bin:$PATH"
VOLUME ["/data"]
EXPOSE 8123
HEALTHCHECK --interval=10s --timeout=3s --start-period=20s --retries=12 CMD ["python","-c","import urllib.request; urllib.request.urlopen('http://127.0.0.1:8123/health',timeout=2)"]
CMD ["uvicorn","app.main:app","--app-dir","backend","--host","0.0.0.0","--port","8123"]
