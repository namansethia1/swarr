# Use an official Python runtime as a parent image
FROM python:3.11-slim as builder

# Install git and build essentials needed for tree-sitter
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory in the container
WORKDIR /app

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.11-slim as production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r swar && useradd -r -g swar swar

# Set the working directory in the container
WORKDIR /app

# Copy Python packages from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# --- Build Tree-sitter Grammars during Docker build ---
# Build tree-sitter languages in builder stage
RUN mkdir -p /app/vendor && cd /app/vendor && \
    git clone https://github.com/tree-sitter/tree-sitter-go && \
    git clone https://github.com/tree-sitter/tree-sitter-javascript && \
    cd /app && \
    python -c "from tree_sitter import Language; Language.build_library('build/languages.so', ['vendor/tree-sitter-go', 'vendor/tree-sitter-javascript'])"

# Copy the compiled languages to production stage
RUN mkdir -p /app/build
COPY --from=builder /app/build/languages.so /app/build/

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p logs && \
    chown -R swar:swar /app

# Switch to non-root user
USER swar

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')" || exit 1

# Run the startup command to launch the FastAPI server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]