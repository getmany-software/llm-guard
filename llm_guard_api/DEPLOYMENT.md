# LLM Guard API Deployment Guide for Render.com

This guide explains how to deploy the LLM Guard API with Prompt Injection detection on Render.com using a persistent disk for model storage.

## Overview

The API uses a 508MB DeBERTa model for prompt injection detection. By storing the model on a persistent disk, we avoid re-downloading it on every deployment and improve cold start times.

## Prerequisites

1. A Render.com account
2. A persistent disk mounted at `/models` (1GB recommended)
3. The LLM Guard repository

## Configuration

### 1. Environment Variables on Render

Set these environment variables in your Render service:

```bash
# Required
AUTH_TOKEN=your_secure_token_here        # API authentication token
PROMPT_INJECTION_MODEL_PATH=/models/prompt-injection-v2  # Path to model on disk

# Optional but recommended
LOG_LEVEL=INFO                           # INFO for production, DEBUG for troubleshooting
SCAN_PROMPT_TIMEOUT=120                  # Timeout for prompt scanning (seconds)
SCAN_OUTPUT_TIMEOUT=120                  # Timeout for output scanning (seconds)
LAZY_LOAD=true                          # Load models on first request
PORT=8000                               # Port for the API (Render sets this)
```

### 2. Files to Commit

Make sure these files are in your repository:

#### `llm_guard_api/config/scanners.yml`
```yaml
app:
  name: ${APP_NAME:LLM Guard API}
  log_level: ${LOG_LEVEL:INFO}
  log_json: ${LOG_JSON:true}
  scan_fail_fast: ${SCAN_FAIL_FAST:false}
  scan_prompt_timeout: ${SCAN_PROMPT_TIMEOUT:120}
  scan_output_timeout: ${SCAN_OUTPUT_TIMEOUT:120}
  lazy_load: ${LAZY_LOAD:true}

rate_limit:
  enabled: ${RATE_LIMIT_ENABLED:false}
  limit: ${RATE_LIMIT_LIMIT:100/minute}

auth:
  type: http_bearer
  token: ${AUTH_TOKEN:}

input_scanners:
  - type: PromptInjection
    params:
      threshold: 0.92
      match_type: truncate_head_tail
      model_max_length: 256
      model_path: ${PROMPT_INJECTION_MODEL_PATH:}

output_scanners: []
```

#### `llm_guard_api/download_models.py`
(Already created - see file in repository)

#### `llm_guard_api/startup.sh`
(Already created - see file in repository)

### 3. Render Build & Start Commands

In your Render service settings:

**Build Command:**
```bash
cd llm_guard_api && pip install -r requirements.txt huggingface_hub
```

**Start Command:**
```bash
cd llm_guard_api && chmod +x startup.sh && ./startup.sh
```

## Deployment Steps

### Step 1: Initial Setup

1. Create a Render Web Service
2. Connect your GitHub repository
3. Create a persistent disk:
   - Mount path: `/models`
   - Size: 1GB (sufficient for one model)

### Step 2: Configure Environment Variables

Add all the environment variables listed above in the Render dashboard.

### Step 3: Deploy

1. Push the configuration files to your repository
2. Trigger a deployment on Render
3. On first deployment, the startup script will:
   - Check if the model exists at `/models/prompt-injection-v2`
   - If not, download it (takes ~2-3 minutes)
   - Start the API server

### Step 4: Verify

Test the deployment:

```bash
# Check health
curl https://your-app.onrender.com/healthz

# Check readiness
curl https://your-app.onrender.com/readyz

# Test prompt injection detection
curl -X POST https://your-app.onrender.com/analyze/prompt \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_token_here" \
  -d '{
    "prompt": "What is the capital of France?",
    "scanners_suppress": []
  }'
```

## Expected Behavior

### First Deployment
- Model download: 2-3 minutes
- Model is saved to persistent disk
- API starts and is ready

### Subsequent Deployments
- Model already on disk
- API starts immediately (< 30 seconds)

### Cold Starts
- If instance sleeps, model loads from disk
- Startup time: 10-20 seconds

## Response Format

```json
{
  "is_valid": true,          // false if injection detected
  "scanners": {
    "PromptInjection": -1.0  // -1.0 = safe, 1.0 = injection
  },
  "sanitized_prompt": "..."  // Original prompt (unchanged in this config)
}
```

## Troubleshooting

### 502 Gateway Timeout on First Request
- **Cause**: Model downloading on first use
- **Solution**: Wait 2-3 minutes for download to complete, or pre-download using startup script

### Model Not Found Errors
- **Cause**: Disk not mounted or path incorrect
- **Solution**: Verify disk is mounted at `/models` and `PROMPT_INJECTION_MODEL_PATH` is set correctly

### Authentication Errors (403)
- **Cause**: Missing or incorrect AUTH_TOKEN
- **Solution**: Set AUTH_TOKEN environment variable and include Bearer token in requests

### Check Logs
```bash
# In Render dashboard, check logs for:
- "Model already exists" (good - using cached model)
- "Model not found. Downloading..." (first time setup)
- "Initialized classification ONNX model" (model loaded successfully)
```

## Performance Notes

- **Model Size**: 508MB on disk, ~2-3GB in memory
- **First Request**: 10-20s if model needs loading
- **Subsequent Requests**: ~130ms
- **Recommended Instance**: At least 2GB RAM

## Local Testing

To test the same setup locally:

```bash
# Download model
python download_models.py --models-dir /tmp/models

# Run with local model
PROMPT_INJECTION_MODEL_PATH=/tmp/models/prompt-injection-v2 \
AUTH_TOKEN=test123 \
LOG_LEVEL=DEBUG \
uvicorn app.app:create_app --host=0.0.0.0 --port=8000
```

## Security Notes

1. Always use a strong AUTH_TOKEN in production
2. Consider using Render's secret files for sensitive configuration
3. Enable rate limiting if exposed to public internet
4. Monitor usage and set up alerts for suspicious activity

## Support

For issues specific to:
- LLM Guard: https://github.com/protectai/llm-guard
- Render deployment: https://render.com/docs
- This configuration: Check logs and environment variables first