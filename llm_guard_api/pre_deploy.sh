#!/bin/bash
# Pre-deploy script for Render
# Downloads models to persistent disk before starting the server

set -e  # Exit on error

echo "🚀 Running pre-deploy tasks for LLM Guard API..."

# Set models directory (Render disk mount point)
MODELS_DIR="${MODELS_DIR:-/models}"
MODEL_PATH="$MODELS_DIR/prompt-injection-v2"

echo "📁 Models directory: $MODELS_DIR"

# Check if model already exists
if [ -f "$MODEL_PATH/onnx/model.onnx" ]; then
    echo "✅ Model already exists at $MODEL_PATH"
    echo "   Skipping download to save time"
else
    echo "📥 Model not found. Downloading..."
    echo "   This will take 2-3 minutes on first deployment"
    
    # Ensure we're in the right directory
    cd /opt/render/project/src/llm_guard_api
    
    # Run the download script
    python download_models.py --models-dir "$MODELS_DIR"
    
    echo "✅ Model download complete!"
fi

# Export the model path for the application
export PROMPT_INJECTION_MODEL_PATH="$MODEL_PATH"

echo "🔧 Pre-deploy complete. Environment configured:"
echo "   PROMPT_INJECTION_MODEL_PATH=$PROMPT_INJECTION_MODEL_PATH"
echo "✨ Ready to start the server!"