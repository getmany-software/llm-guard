# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

LLM Guard is a comprehensive security toolkit for Large Language Model interactions, providing sanitization, harmful language detection, data leakage prevention, and prompt injection protection. This is a defensive security library designed to protect LLM applications.

## Core Architecture

### Scanner-Based Architecture
The system uses a pipeline of scanners that process input prompts and output responses:
- **Input Scanners** (`llm_guard/input_scanners/`): Process and validate user prompts before sending to LLMs
- **Output Scanners** (`llm_guard/output_scanners/`): Validate and sanitize LLM responses
- Each scanner inherits from base classes defining `scan()` method returning: (processed_text, is_valid, risk_score)

### Main Entry Points
- `scan_prompt()` in `llm_guard/evaluate.py`: Chains input scanners on prompts
- `scan_output()` in `llm_guard/evaluate.py`: Chains output scanners on LLM outputs
- Scanners can be configured for fail-fast mode or complete evaluation

### Scanner Categories
- **Security**: PromptInjection, Secrets, BanCode, InvisibleText
- **Content Filtering**: Toxicity, BanTopics, BanCompetitors, BanSubstrings
- **PII Protection**: Anonymize (input), Deanonymize (output), Sensitive
- **Quality Control**: Gibberish, Language, Sentiment, Bias
- **Technical**: TokenLimit, Code, JSON, Regex

## Development Commands

### Installation
```bash
# Development environment with all dependencies
make install-dev
# Or manually:
python -m pip install ".[dev, onnxruntime]" -U
pre-commit install
```

### Code Quality
```bash
# Run all linters and formatters
make lint
# Or manually:
pre-commit run --all-files

# Type checking (included in pre-commit)
pyright

# Code formatting (included in pre-commit)
ruff format --force-exclude
ruff check --force-exclude --fix
```

### Testing
```bash
# Run all tests with coverage
make test
# Or manually:
pytest --exitfirst --verbose --failed-first --cov=.

# Run specific test file
pytest tests/input_scanners/test_prompt_injection.py -v

# Run specific test
pytest tests/input_scanners/test_prompt_injection.py::TestPromptInjection::test_scan -v
```

### Documentation
```bash
# Serve documentation locally
make docs-serve
# Access at: http://localhost:8085
```

### Building & Publishing
```bash
# Build package
make build

# Clean build artifacts
make clean
```

## API Deployment

The project includes a FastAPI-based API service in `llm_guard_api/`:
- Configuration: `llm_guard_api/config/scanners.yml`
- Docker support with CPU and CUDA variants
- OpenTelemetry integration for monitoring

## Key Implementation Notes

### Adding New Scanners
1. Create scanner in appropriate directory (`input_scanners/` or `output_scanners/`)
2. Inherit from `Scanner` base class
3. Implement `scan()` method returning (sanitized_text, is_valid, risk_score)
4. Add tests in corresponding test directory
5. Update documentation in `docs/` directory

### Model Management
- Uses Hugging Face Transformers for ML models
- Supports ONNX runtime optimization
- Model caching handled by `transformers_helpers.py`
- Language detection caches models to avoid unnecessary downloads

### Secret Detection
- Extensive plugin system in `secrets_plugins/` for various API key patterns
- Based on `bc-detect-secrets` library
- Each plugin defines regex patterns for specific service tokens

### Dependencies
- **Core**: transformers, torch, presidio (PII detection), nltk
- **Development**: pytest, pyright, ruff, pre-commit
- **Python**: 3.10-3.12 supported