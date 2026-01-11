# ============================================
# Stage 1: Build React UI
# ============================================
FROM node:22-alpine AS ui-builder

WORKDIR /build/app/ui

# Copy UI source
COPY app/ui/package*.json ./
RUN npm ci --silent

COPY app/ui/ ./

# Build UI (outputs to ../api/www = /build/app/api/www)
RUN npm run build

# ============================================
# Stage 2: Python API Runtime
# ============================================
FROM python:3.12-slim AS runtime

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY app/api/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY common/ /app/common/
COPY app/api/ /app/

# Copy built UI from Stage 1
COPY --from=ui-builder /build/app/api/www /app/www/

# Create data directories
RUN mkdir -p /app/data/documents /app/data/mineru

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/api/health')" || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
