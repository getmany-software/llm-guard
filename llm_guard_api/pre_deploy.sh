#!/bin/bash
# Pre-deploy script for Render
# Downloads models to persistent disk before starting the server

# Don't exit on error immediately - we want to see what fails
set +e

echo "==================================================="
echo "🚀 STARTING PRE-DEPLOY SCRIPT FOR LLM GUARD"
echo "==================================================="
echo "Current directory: $(pwd)"
echo "Directory contents:"
ls -la

# Set models directory (Render disk mount point)
MODELS_DIR="${MODELS_DIR:-/models}"
MODEL_PATH="$MODELS_DIR/prompt-injection-v2"

echo ""
echo "📁 Configuration:"
echo "   MODELS_DIR=$MODELS_DIR"
echo "   MODEL_PATH=$MODEL_PATH"
echo ""

# Check if models directory exists
if [ ! -d "$MODELS_DIR" ]; then
    echo "❌ ERROR: Models directory $MODELS_DIR does not exist!"
    echo "   Checking if /models exists:"
    ls -la /models 2>&1 || echo "   /models does not exist"
    echo "   Creating directory..."
    mkdir -p "$MODELS_DIR" || echo "   Failed to create directory"
fi

echo "📂 Checking for existing model..."
if [ -f "$MODEL_PATH/onnx/model.onnx" ]; then
    echo "✅ Model already exists at $MODEL_PATH"
    echo "   File size: $(du -h $MODEL_PATH/onnx/model.onnx | cut -f1)"
    echo "   Skipping download"
else
    echo "⚠️  Model NOT found at $MODEL_PATH/onnx/model.onnx"
    echo "   Checking what's in $MODELS_DIR:"
    ls -la "$MODELS_DIR" 2>&1 || echo "   Cannot list $MODELS_DIR"
    
    echo ""
    echo "📥 Starting model download..."
    echo "   Running: python download_models.py --models-dir $MODELS_DIR"
    
    # Run the download script with full output
    python download_models.py --models-dir "$MODELS_DIR" 2>&1
    DOWNLOAD_EXIT_CODE=$?
    
    if [ $DOWNLOAD_EXIT_CODE -eq 0 ]; then
        echo "✅ Download script completed successfully"
    else
        echo "❌ Download script failed with exit code: $DOWNLOAD_EXIT_CODE"
    fi
    
    # Verify the model was actually downloaded
    if [ -f "$MODEL_PATH/onnx/model.onnx" ]; then
        echo "✅ Model verified at $MODEL_PATH/onnx/model.onnx"
        echo "   File size: $(du -h $MODEL_PATH/onnx/model.onnx | cut -f1)"
    else
        echo "❌ ERROR: Model still not found after download!"
        echo "   Contents of $MODELS_DIR:"
        find "$MODELS_DIR" -type f -name "*.onnx" 2>&1 || echo "   No .onnx files found"
    fi
fi

# Export the model path for the application
export PROMPT_INJECTION_MODEL_PATH="$MODEL_PATH"

echo ""
echo "🔧 Environment variables:"
echo "   PROMPT_INJECTION_MODEL_PATH=$PROMPT_INJECTION_MODEL_PATH"
echo "   AUTH_TOKEN=${AUTH_TOKEN:0:10}..." 
echo ""
echo "==================================================="
echo "✨ PRE-DEPLOY SCRIPT COMPLETE"
echo "==================================================="