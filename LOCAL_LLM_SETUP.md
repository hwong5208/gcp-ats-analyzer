# Local LLM Setup Guide

Quick guide to test the ATS analyzer with your local LLM.

## Prerequisites

- Local LLM server running on `http://10.0.0.95:1234/v1/chat/completions`
  - Model: `HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive`
  - API format: OpenAI-compatible

## Start the App

### PowerShell (Windows)
```powershell
$env:LOCAL_LLM_ENDPOINT = "http://10.0.0.95:1234/v1/chat/completions"
$env:LOCAL_LLM_MODEL = "HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
bash scripts/local-dev.sh
```

### Command Prompt (Windows)
```cmd
set LOCAL_LLM_ENDPOINT=http://10.0.0.95:1234/v1/chat/completions
set LOCAL_LLM_MODEL=HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive
scripts\local-dev.bat
```

### Bash (Mac/Linux)
```bash
export LOCAL_LLM_ENDPOINT="http://10.0.0.95:1234/v1/chat/completions"
export LOCAL_LLM_MODEL="HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
chmod +x scripts/local-dev.sh
./scripts/local-dev.sh
```

## Test the Setup

1. **Check container logs** (in another terminal):
```bash
docker-compose logs app
```

Look for:
```
✅ Local LLM configured: http://10.0.0.95:1234/v1/chat/completions
```

2. **Test the health endpoint**:
```bash
curl http://localhost:8000/health
```

Expected:
```json
{"status": "healthy", "service": "gcp-ats-analyzer"}
```

3. **Test the analyze endpoint**:
```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "job_description": "We need a Cloud DevOps Engineer with Kubernetes and Terraform experience",
    "resume_text": "I have 5 years experience with Kubernetes, Docker, and infrastructure automation"
  }'
```

Expected: ATS analysis with score, keywords, feedback

4. **Test in browser**:
   - Open `http://localhost:8000`
   - Paste a job description
   - Upload a resume PDF or paste text
   - Click "Analyze"
   - Should see results with ATS score and feedback

## Troubleshooting

### "Connection refused" for local LLM
- Verify local LLM is running on `http://10.0.0.95:1234`
- On Docker Desktop (Windows/Mac), check that `10.0.0.95` is accessible from the container
- If needed, use `host.docker.internal` instead: `http://host.docker.internal:1234/v1/chat/completions`

### "Model not found" error
- Verify the model name matches your local LLM: `HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive`
- Check that the model is loaded/running in your local LLM server

### Container can't reach host machine
If running on Windows/Mac Docker Desktop, the host machine is accessible via `host.docker.internal`:
```powershell
$env:LOCAL_LLM_ENDPOINT = "http://host.docker.internal:1234/v1/chat/completions"
```

On Linux, the host machine is typically at `172.17.0.1` (check with `ip addr`).

## Switching to Vertex AI

To switch from local LLM to Vertex AI, unset the local LLM variables and set GCP credentials:

```bash
unset LOCAL_LLM_ENDPOINT
unset LOCAL_LLM_MODEL

export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

docker-compose up
```

Or clear and restart:
```bash
docker-compose down
# Set GCP environment variables
docker-compose up
```

## Performance Notes

- **Cold start**: First call may take a few seconds as the local LLM loads
- **Latency**: Should be fast (~1-3 seconds) compared to Vertex AI (~2-5 seconds)
- **Memory**: Local LLM will use significant system memory
- **Cost**: Free (no API calls)
