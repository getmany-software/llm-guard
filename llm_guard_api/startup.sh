#!/bin/bash
# Startup script for LLM Guard API on Render
# This script downloads the model if not present, then starts the API server

set -e  # Exit on error

echo "🚀 Starting LLM Guard API..."

# Set default models directory (Render disk mount point)
MODELS_DIR="${MODELS_DIR:-/models}"
MODEL_PATH="$MODELS_DIR/prompt-injection-v2"

echo "📁 Models directory: $MODELS_DIR"

# Check if model already exists
if [ -f "$MODEL_PATH/onnx/model.onnx" ]; then
    echo "✅ Model already exists at $MODEL_PATH"
else
    echo "📥 Model not found. Downloading..."
    python download_models.py --models-dir "$MODELS_DIR"
fi

# Export the model path for the application
export PROMPT_INJECTION_MODEL_PATH="$MODEL_PATH"

echo "🔧 Environment variables:"
echo "   PROMPT_INJECTION_MODEL_PATH=$PROMPT_INJECTION_MODEL_PATH"
echo "   AUTH_TOKEN=${AUTH_TOKEN:0:5}..." # Show first 5 chars only
echo "   LOG_LEVEL=${LOG_LEVEL:-INFO}"

# Start the API server
echo "🌐 Starting Uvicorn server..."
exec uvicorn app.app:create_app \
    --host=0.0.0.0 \
    --port=${PORT:-8000} \
    --workers=1 \
    --forwarded-allow-ips="*" \
    --proxy-headers \
    --timeout-keep-alive="2"