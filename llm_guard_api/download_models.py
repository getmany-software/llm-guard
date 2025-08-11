#!/usr/bin/env python3
"""
Download and cache models for LLM Guard API.
This script downloads the PromptInjection model to a local directory.

Usage:
    python download_models.py [--models-dir /models]
"""

import os
import sys
import argparse
from pathlib import Path
from huggingface_hub import snapshot_download


def download_prompt_injection_model(models_dir: str):
    """Download the PromptInjection v2 model to the specified directory."""
    
    model_name = "protectai/deberta-v3-base-prompt-injection-v2"
    model_path = os.path.join(models_dir, "prompt-injection-v2")
    
    print(f"📥 Downloading {model_name} to {model_path}...")
    
    try:
        # Create directory if it doesn't exist
        Path(model_path).mkdir(parents=True, exist_ok=True)
        
        # Download the ONNX version of the model
        snapshot_download(
            repo_id=model_name,
            local_dir=model_path,
            local_dir_use_symlinks=False,
            revision="89b085cd330414d3e7d9dd787870f315957e1e9f",
            allow_patterns=["onnx/*", "tokenizer*", "*.json", "*.txt"],
            ignore_patterns=["*.bin", "*.safetensors", "*.h5", "*.msgpack"]
        )
        
        print(f"✅ Model downloaded successfully to {model_path}")
        print(f"   Size: ~508MB")
        print(f"   Files: ONNX model + tokenizer")
        
        # Verify the model files exist
        onnx_file = os.path.join(model_path, "onnx", "model.onnx")
        if os.path.exists(onnx_file):
            size_mb = os.path.getsize(onnx_file) / (1024 * 1024)
            print(f"   ONNX model size: {size_mb:.1f}MB")
        else:
            print("⚠️  Warning: ONNX model file not found at expected location")
            
        return model_path
        
    except Exception as e:
        print(f"❌ Error downloading model: {e}")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Download models for LLM Guard API")
    parser.add_argument(
        "--models-dir",
        type=str,
        default=os.environ.get("MODELS_DIR", "/models"),
        help="Directory to store downloaded models (default: /models or MODELS_DIR env var)"
    )
    
    args = parser.parse_args()
    
    print(f"🚀 LLM Guard Model Downloader")
    print(f"📁 Models directory: {args.models_dir}")
    
    # Check if directory exists and is writable
    if not os.path.exists(args.models_dir):
        try:
            Path(args.models_dir).mkdir(parents=True, exist_ok=True)
            print(f"✅ Created models directory: {args.models_dir}")
        except PermissionError:
            print(f"❌ Error: Cannot create directory {args.models_dir}. Permission denied.")
            print("   Try running with sudo or use a different directory.")
            sys.exit(1)
    
    if not os.access(args.models_dir, os.W_OK):
        print(f"❌ Error: Directory {args.models_dir} is not writable.")
        sys.exit(1)
    
    # Download the model
    model_path = download_prompt_injection_model(args.models_dir)
    
    print("\n📝 Configuration:")
    print(f"   Add this to your scanners.yml:")
    print(f"   model_path: {model_path}")
    print(f"\n   Or set environment variable:")
    print(f"   PROMPT_INJECTION_MODEL_PATH={model_path}")
    
    print("\n✨ Done! Model is ready to use.")


if __name__ == "__main__":
    main()