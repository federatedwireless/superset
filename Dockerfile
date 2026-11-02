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

    # FW additions (DB drivers, reports deps, AI assistant) baked in at build time
    # from a fully hash-locked closure, instead of being pip-installed from public
    # PyPI on every pod start. --require-hashes rejects any distribution whose hash
    # isn't in the lock; --no-deps stops uv from resolving anything outside it.
    # Regenerate the lock per requirements/fw-extras.in.
    COPY requirements/fw-extras.txt /app/requirements/fw-extras.txt
    RUN . /app/.venv/bin/activate && \
        uv pip install --require-hashes --no-deps -r /app/requirements/fw-extras.txt && \
        python -c "import importlib.util as u, sys; m=['trino','trino.sqlalchemy','psycopg2','authlib','PIL','slack_sdk','superset_chat','langchain_mcp_adapters']; miss=[x for x in m if u.find_spec(x) is None]; sys.exit('missing: %s' % miss if miss else 0)"

    USER superset