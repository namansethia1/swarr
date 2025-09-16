# Use an official Python runtime as a parent image
FROM python:3.10-slim

# Install git and build essentials needed for tree-sitter
RUN apt-get update && apt-get install -y git build-essential

# Set the working directory in the container
WORKDIR /app

# Install Python dependencies first
# Pinned tree-sitter to a compatible version (0.20.4) to fix the build error.
RUN pip install --no-cache-dir fastapi "uvicorn[standard]" scikit-learn joblib pandas "tree-sitter==0.20.4" python-multipart

# --- Build Tree-sitter Grammars during Docker build ---
# We've replaced the Python grammar with the Go grammar.
WORKDIR /app/vendor
RUN git clone https://github.com/tree-sitter/tree-sitter-go && \
    git clone https://github.com/tree-sitter/tree-sitter-javascript

WORKDIR /app
RUN python -c "from tree_sitter import Language; Language.build_library('build/languages.so', ['vendor/tree-sitter-go', 'vendor/tree-sitter-javascript'])"
# --- End of Tree-sitter build section ---

# Copy the rest of the application's code
COPY . .

# Run the startup command to launch the FastAPI server
# The host 0.0.0.0 makes it accessible from outside the container
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]