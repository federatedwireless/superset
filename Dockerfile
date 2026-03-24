# ---------- Stage 1: Build frontend ----------
    FROM node:20 AS frontend-builder

    RUN apt-get update && apt-get install -y \
        build-essential \
        python3 \
        zstd \
        && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # ✅ IMPORTANT: create expected output directory
    RUN mkdir -p /app/superset/static/assets
    
    # Copy frontend
    COPY superset-frontend ./superset-frontend
    
    WORKDIR /app/superset-frontend
    
    RUN npm ci
    RUN npm run build
    
    
    # ---------- Stage 2 ----------
    FROM apache/superset:5.0.0
    
    USER root
    
    # ✅ NOW this path exists
    COPY --from=frontend-builder /app/superset/static/assets \
        /app/superset/static/assets
    
    USER superset