#!/usr/bin/env python3
"""
Manual model download script for Render deployment.
Run this in Render's shell to download the model to disk.
"""

import os
import sys
from huggingface_hub import snapshot_download

print("🚀 Manual Model Download for LLM Guard")
print("=" * 50)

models_dir = "/models"
model_name = "protectai/deberta-v3-base-prompt-injection-v2"
model_path = os.path.join(models_dir, "prompt-injection-v2")

print(f"📁 Target directory: {model_path}")

# Check if model already exists
onnx_file = os.path.join(model_path, "onnx", "model.onnx")
if os.path.exists(onnx_file):
    size_mb = os.path.getsize(onnx_file) / (1024 * 1024)
    print(f"✅ Model already exists! Size: {size_mb:.1f}MB")
    print("No download needed.")
    sys.exit(0)

print(f"📥 Downloading {model_name}...")
print("This will take 2-3 minutes...")

try:
    # Download the ONNX version
    snapshot_download(
        repo_id=model_name,
        local_dir=model_path,
        local_dir_use_symlinks=False,
        revision="89b085cd330414d3e7d9dd787870f315957e1e9f",
        allow_patterns=["onnx/*", "tokenizer*", "*.json", "*.txt"],
        ignore_patterns=["*.bin", "*.safetensors", "*.h5", "*.msgpack"]
    )
    
    print(f"✅ Model downloaded successfully to {model_path}")
    
    # Verify the model
    if os.path.exists(onnx_file):
        size_mb = os.path.getsize(onnx_file) / (1024 * 1024)
        print(f"   ONNX model size: {size_mb:.1f}MB")
        print("\n🎉 SUCCESS! Model is ready to use.")
        print("Now restart your service to use the downloaded model.")
    else:
        print("⚠️  Warning: Model file not found at expected location")
        
except Exception as e:
    print(f"❌ Error downloading model: {e}")
    sys.exit(1)