# ============================================
# Stage 1: Build React UI
# ============================================
FROM node:22-alpine AS ui-builder

WORKDIR /workspace/app/ui

# Copy UI source
COPY app/ui/package*.json ./
RUN npm ci --silent

COPY app/ui/ ./

# Build UI (outputs to ../api/www = /workspace/app/api/www)
RUN npm run build

# ============================================
# Stage 2: Python API Runtime
# ============================================
FROM python:3.12-slim AS runtime

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    # Override config paths for container structure
    LOCAL_DOCS_DIR=/workspace/app/data/documents \
    SQLITE_PATH=/workspace/app/data/app.db \
    MINERU_CACHE_DIR=/workspace/app/data/mineru

# Mirror local structure: /workspace as project root
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY app/api/requirements.txt ./app/api/requirements.txt
RUN pip install --no-cache-dir -r ./app/api/requirements.txt

# Copy application code (same structure as local)
COPY common/ ./common/
COPY app/api/ ./app/api/

# Copy built UI from Stage 1
COPY --from=ui-builder /workspace/app/api/www ./app/api/www/

# Create data directories (same as local)
RUN mkdir -p ./app/data/documents ./app/data/mineru

# Expose port
EXPOSE 8080

# Set working directory to API folder
WORKDIR /workspace/app/api

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/api/health')" || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
