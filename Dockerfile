# ---------- Stage 1: Build frontend ----------
    FROM node:20 AS frontend-builder

    # Install system dependencies required by Superset build
    RUN apt-get update && apt-get install -y \
        build-essential \
        python3 \
        zstd \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy frontend source
    COPY superset-frontend ./superset-frontend
    
    WORKDIR /app/superset-frontend
    
    # Install dependencies
    RUN npm ci
    
    # Build frontend
    RUN npm run build
    
    
    # ---------- Stage 2: Superset runtime ----------
    FROM apache/superset:5.0.0
    
    USER root
    
    # Replace frontend assets
    COPY --from=frontend-builder /app/superset-frontend/build \
        /app/superset/static/assets
    
    USER superset