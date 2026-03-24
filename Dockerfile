# ---------- Stage 1: Build frontend ----------
    FROM node:20 AS frontend-builder

    WORKDIR /app
    
    # Copy frontend source
    COPY superset-frontend ./superset-frontend
    
    WORKDIR /app/superset-frontend
    
    # Install deps and build
    RUN npm ci
    RUN npm run build
    
    
# ---------- Stage 2: Superset runtime ----------
    FROM apache/superset:5.0.0
    
    USER root
    
    # Replace frontend assets
    COPY --from=frontend-builder /app/superset-frontend/build \
        /app/superset/static/assets
    
    USER superset