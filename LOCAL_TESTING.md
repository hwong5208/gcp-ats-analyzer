# Local Testing Guide - Phase 1

Quick setup to verify frontend and backend are working locally.

## Prerequisites

- Docker Desktop (includes docker-compose)
- Git Bash (Windows) or any terminal with bash
- Optional: GCP credentials for real Vertex AI testing

## Quick Start (Docker)

### Option 1: Using local LLM (Recommended for testing)

If you have a local LLM running on `http://10.0.0.95:1234/v1/chat/completions`, set the environment variables:

**On Linux/Mac:**
```bash
export LOCAL_LLM_ENDPOINT="http://10.0.0.95:1234/v1/chat/completions"
export LOCAL_LLM_MODEL="HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
chmod +x scripts/local-dev.sh
./scripts/local-dev.sh
```

**On Windows (PowerShell):**
```powershell
$env:LOCAL_LLM_ENDPOINT = "http://10.0.0.95:1234/v1/chat/completions"
$env:LOCAL_LLM_MODEL = "HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
bash scripts/local-dev.sh
```

**On Windows (Command Prompt):**
```cmd
set LOCAL_LLM_ENDPOINT=http://10.0.0.95:1234/v1/chat/completions
set LOCAL_LLM_MODEL=HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive
scripts\local-dev.bat
```

### Option 2: Direct docker-compose command

```bash
# Set environment variables first (see above), then:
docker-compose up
```

This will:
- Build the Docker image from `app/Dockerfile`
- Start the FastAPI backend on `http://localhost:8000`
- Serve the frontend SPA from the same origin
- Enable hot-reload for code changes
- Connect to your local LLM (or Vertex AI as fallback)

## Testing the Application

Once services are running, open your browser:

```
http://localhost:8000
```

### Frontend Verification Checklist

- [ ] Page loads with title "Resume ATS Analyzer"
- [ ] Job Description textarea is visible
- [ ] PDF upload zone is visible with drag-drop support
- [ ] "Analyze" button is visible

### Backend API Testing

#### Health Check
```bash
curl http://localhost:8000/health
```

Expected response:
```json
{
  "status": "healthy",
  "service": "gcp-ats-analyzer"
}
```

#### Analyze Endpoint (with mock data)
```bash
curl -X POST http://localhost:8000/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "job_description": "We are looking for a DevOps engineer with Kubernetes experience",
    "resume_text": "I am a software engineer with 5 years of experience in Kubernetes and Docker"
  }'
```

Expected response (with real GCP credentials):
```json
{
  "ats_score": 78,
  "matching_keywords": ["Kubernetes", "Docker", "DevOps"],
  "missing_keywords": [],
  "actionable_feedback": "..."
}
```

### E2E Test (With Frontend)

1. Open `http://localhost:8000` in browser
2. Paste a job description in the textarea
3. Upload a test PDF resume (or use the mock approach below)
4. Click "Analyze"
5. Verify results display

## LLM Backend Options

The app supports multiple LLM backends in this order of preference:

### Option 1: Use Local LLM (⭐ Recommended for testing)

If you have a local LLM running (e.g., Ollama, LM Studio, vLLM):

```bash
export LOCAL_LLM_ENDPOINT="http://10.0.0.95:1234/v1/chat/completions"
export LOCAL_LLM_MODEL="HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
docker-compose up
```

**Advantages:**
- No GCP credentials needed
- Instant feedback (no network latency)
- Fast iteration during development
- Free (if running locally)

### Option 2: Use Vertex AI (GCP)

If you have a GCP project with Vertex AI enabled:

1. Create a service account in your GCP project:
```bash
gcloud iam service-accounts create ats-analyzer-dev \
  --display-name="ATS Analyzer Dev"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:ats-analyzer-dev@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/aiplatform.user
```

2. Create and download a service account key:
```bash
gcloud iam service-accounts keys create /path/to/service-account-key.json \
  --iam-account=ats-analyzer-dev@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

3. Set environment variables:
```bash
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"

docker-compose up
```

### Option 3: Mock the API response

Edit `app/static/app.js` temporarily (quick testing without any LLM):

Find the `submitForm()` function and replace the fetch call with:

```javascript
// MOCK RESPONSE - remove before deploying
const mockResponse = {
  ats_score: 85,
  matching_keywords: ["Python", "Docker", "Kubernetes"],
  missing_keywords: ["Terraform", "GCP"],
  actionable_feedback: "Your technical background aligns well. Consider adding infrastructure-as-code experience."
};
renderResults(mockResponse);
isAnalyzing = false;
```

## Troubleshooting

### "Port 8000 is already in use"
```bash
# Find and stop the process using port 8000
lsof -i :8000  # Linux/Mac
netstat -ano | findstr :8000  # Windows
```

Or use a different port in docker-compose.yml:
```yaml
ports:
  - "8001:8000"  # Access on localhost:8001
```

### "Cannot find module pdf.js"
The PDF.js library is loaded from CDN in `index.html`. Ensure internet connection is available.

### Vertex AI returns 401/403 errors
- Verify `GOOGLE_APPLICATION_CREDENTIALS` points to a valid key file
- Check the service account has `roles/aiplatform.user` role
- Verify Vertex AI API is enabled: `gcloud services enable aiplatform.googleapis.com`

### Container fails to start
Check logs:
```bash
docker-compose logs app
```

Common issues:
- Missing `requirements.txt` dependencies → rebuild: `docker-compose up --build`
- Python syntax errors in `main.py` → check logs for traceback
- Port conflict → change port in docker-compose.yml

## Stopping Services

Press `Ctrl+C` to stop the running services, or in another terminal:

```bash
docker-compose down
```

## Next Steps

Once local testing is verified:
1. Deploy to GCP using Terraform: `cd infrastructure && terraform apply`
2. View deployment status: `gcloud run services describe gcp-ats-analyzer-dev --region us-central1`
3. Begin Phase 2: Add Grafana monitoring and Firestore telemetry
