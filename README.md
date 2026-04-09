# GCP ATS Analyzer — Phase 1: Main App

A Cloud DevOps portfolio project showcasing:
- **FastAPI** backend with Vertex AI Gemini integration
- **Docker** containerization
- **Terraform** infrastructure as code
- **Cloud Run** serverless deployment
- **GitHub Actions** CI/CD pipeline
- Resume vs. Job Description ATS (Applicant Tracking System) analysis

## Quick Start

### Local Development

#### Prerequisites
- Python 3.12+
- Docker
- GCP account with Vertex AI enabled

#### 1. Set up environment
```bash
cd app
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt
```

#### 2. Configure GCP credentials
```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
```

#### 3. Run locally
```bash
python main.py
```

The app will be available at `http://localhost:8000`

---

### Docker Build & Run

```bash
cd app
docker build -t gcp-ats-analyzer:latest .
docker run -p 8000:8000 \
  -e GCP_PROJECT_ID="your-project-id" \
  -e GCP_REGION="us-central1" \
  -v ~/.config/gcloud:/home/appuser/.config/gcloud:ro \
  gcp-ats-analyzer:latest
```

---

### Terraform Deployment

#### 1. Prepare Terraform variables
```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

#### 2. Initialize and plan
```bash
terraform init
terraform plan
```

#### 3. Apply
```bash
terraform apply
```

#### 4. Get the Cloud Run URL
```bash
terraform output cloud_run_service_url
```

---

### GitHub Actions Deployment

To enable auto-deployment on push to `main`:

1. **Set up Workload Identity Federation (WIF)** for GitHub Actions:
   ```bash
   gcloud iam service-accounts create github-actions \
     --display-name="GitHub Actions"
   
   # Grant necessary permissions...
   gcloud projects add-iam-policy-binding $(gcloud config get-value project) \
     --member=serviceAccount:github-actions@$(gcloud config get-value project).iam.gserviceaccount.com \
     --role=roles/run.admin
   
   # Configure WIF...
   # (Detailed steps at https://github.com/google-github-actions/auth#setup)
   ```

2. **Add GitHub secrets**:
   - `GCP_PROJECT_ID`: Your GCP project ID
   - `WIF_PROVIDER`: Workload Identity Provider URL
   - `WIF_SERVICE_ACCOUNT`: Service account email

3. **Push to main** to trigger deployment

---

## API Endpoints

### POST /analyze
Analyze a resume against a job description using Vertex AI.

**Request:**
```json
{
  "job_description": "Cloud DevOps Engineer...",
  "resume_text": "I am a software engineer with 5 years of experience..."
}
```

**Response:**
```json
{
  "ats_score": 78,
  "matching_keywords": ["Kubernetes", "Terraform", "Python", "AWS"],
  "missing_keywords": ["GCP", "ArgoCD", "Helm"],
  "actionable_feedback": "Your technical skills align well. Consider adding cloud-specific certifications like GCP Professional Cloud Architect to improve match."
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "gcp-ats-analyzer"
}
```

---

## Architecture

### Frontend (SPA)
- **Framework**: Vanilla JavaScript + Tailwind CSS
- **Features**: PDF resume parsing (client-side), real-time validation, interactive results
- **Served by**: FastAPI StaticFiles (same-origin, no CORS needed)

### Backend (FastAPI)
- **Language**: Python 3.12
- **AI Service**: Vertex AI Gemini 2.0 Flash
- **Features**: Resume analysis, health check
- **Deployment**: Cloud Run (scale-to-zero, min=0, max=2)

### Infrastructure (Terraform)
- **Service Account**: Dedicated SA with minimal IAM permissions
- **APIs Enabled**: Cloud Run, Artifact Registry, Vertex AI, Logging, Monitoring
- **IAM Roles**: 
  - `roles/aiplatform.user` (Vertex AI access)
  - `roles/logging.logWriter` (Cloud Logging)
  - `roles/monitoring.metricWriter` (Cloud Monitoring)

### CI/CD (GitHub Actions)
- **Trigger**: Push to `main` or `develop` branch
- **Steps**:
  1. Authenticate with GCP via Workload Identity Federation
  2. Build Docker image
  3. Push to Artifact Registry
  4. Deploy to Cloud Run
- **Status**: Outputs Cloud Run URL upon success

---

## Project Structure

```
gcp-app/
├── app/
│   ├── main.py                  # FastAPI server + Vertex AI integration
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Multi-stage optimized image
│   ├── .dockerignore           # Docker build excludes
│   └── static/
│       ├── index.html          # Frontend SPA
│       ├── app.js              # Client-side logic
│       └── styles.css          # Tailwind + custom styles
├── infrastructure/
│   ├── providers.tf            # GCP provider configuration
│   ├── main.tf                 # GCP resources (Cloud Run, etc.)
│   ├── variables.tf            # Terraform variables
│   ├── outputs.tf              # Terraform outputs
│   └── terraform.tfvars.example
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD
└── .gitignore
```

---

## Cost Estimation (Free/Dev Tier)

| Service | Free Tier | Usage |
|---|---|---|
| **Cloud Run** | 2M requests/month + 360K GB-seconds | Our app: ~5-100 requests/day |
| **Vertex AI** | N/A (cheap pay-as-you-go) | ~$0.001 per analysis call |
| **Artifact Registry** | 0.5GB free | Docker image: ~300MB |
| **Cloud Logging** | 50GB/month | Minimal (health checks + errors) |

**Estimated monthly cost for demo/showcase**: **$0–$2**

---

## Troubleshooting

### "Vertex AI initialization failed"
- Ensure `google-cloud-aiplatform` is installed
- Verify GCP credentials are set (`GOOGLE_APPLICATION_CREDENTIALS`)
- Confirm Vertex AI API is enabled: `gcloud services enable aiplatform.googleapis.com`

### "Cloud Run deployment failed"
- Check service account has `roles/run.admin` permission
- Verify Docker image is in Artifact Registry
- Review Cloud Run logs: `gcloud run services describe gcp-ats-analyzer-dev --region us-central1`

### "PDF parsing fails"
- Ensure PDF is text-based (not scanned/image-only)
- Try with a simple test PDF first
- Check browser console for errors

---

## Next Steps (Phase 2)

Phase 2 will add:
- **Firestore** for visit telemetry
- **Grafana** monitoring dashboard (Cloud Run service)
- **Prometheus-compatible** endpoints for metrics
- **Local docker-compose** stack for development

---

## Security Considerations

- Service account has minimal permissions (principle of least privilege)
- Cloud Run scales to zero (no idle costs, reduced attack surface)
- API calls to Vertex AI use default Google API authentication
- Frontend runs in-browser PDF parsing (no files sent to backend)
- CORS is not needed (frontend served from same origin)

---

## Contributing

To add features or fixes:
1. Create a feature branch
2. Test locally with Docker
3. Push to `develop` branch for testing
4. Create a PR to `main` for deployment

---

