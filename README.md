# GCP ATS Analyzer — Cloud DevOps Portfolio

A production-ready Cloud DevOps project showcasing modern GCP infrastructure and deployment practices.

**Live Demo:** https://gcp-ats-analyzer-dev-jsg2hvecfa-uw.a.run.app/

## Features
- **FastAPI** backend with Vertex AI Gemini 2.0 Flash integration
- **Docker** containerization with optimized images
- **Terraform** infrastructure as code (IaC)
- **Cloud Run** serverless deployment (scale-to-zero)
- **GitHub Actions** manual CI/CD pipeline with service account authentication
- **CORS middleware** for cross-origin requests
- Resume vs. Job Description ATS (Applicant Tracking System) analysis using AI

## Quick Start

### Local Development

#### Prerequisites
- Python 3.11+
- Docker
- GCP account with Vertex AI API enabled
- gcloud CLI (for credentials)

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
export GCP_REGION="us-west1"
```

#### 3. Run locally
```bash
python main.py
```

The app will be available at `http://localhost:8000`

---

### Docker Build & Run

```bash
docker build -t gcp-ats-analyzer:latest .
docker run -p 8000:8000 \
  -e GCP_PROJECT_ID="your-project-id" \
  -e GCP_REGION="us-west1" \
  -v ~/.config/gcloud:/root/.config/gcloud:ro \
  gcp-ats-analyzer:latest
```

Then visit `http://localhost:8000` in your browser.

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

Manual deployment pipeline with service account authentication.

1. **Create a service account for CI/CD**:
   ```bash
   gcloud iam service-accounts create github-cicd --display-name="GitHub CI/CD"
   
   # Grant Cloud Run admin role
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="serviceAccount:github-cicd@PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/run.admin"
   
   # Grant Artifact Registry writer role
   gcloud projects add-iam-policy-binding PROJECT_ID \
     --member="serviceAccount:github-cicd@PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/artifactregistry.writer"
   ```

2. **Create and download service account key**:
   ```bash
   gcloud iam service-accounts keys create ~/github-key.json \
     --iam-account=github-cicd@PROJECT_ID.iam.gserviceaccount.com
   ```

3. **Add GitHub secret**:
   - Go to GitHub repo → **Settings** → **Secrets and variables** → **Actions**
   - Add secret `GCP_SA_KEY` with the contents of `~/github-key.json`

4. **Trigger deployment**:
   - Go to GitHub repo → **Actions** tab
   - Select **Build & Deploy to Cloud Run**
   - Click **Run workflow** → select **dev** → **Run workflow**
   - Monitor the deployment in real-time

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
- **Trigger**: Manual workflow dispatch (click "Run workflow")
- **Steps**:
  1. Check out code
  2. Authenticate with GCP using service account key
  3. Configure Docker authentication
  4. Build Docker image (tagged with commit SHA)
  5. Push to Artifact Registry (both `latest` and SHA tags)
  6. Deploy to Cloud Run (update existing service)
- **Output**: Cloud Run service URL upon success

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
- Ensure `google-cloud-aiplatform` is installed: `pip install google-cloud-aiplatform`
- Verify GCP credentials are set: `echo $GOOGLE_APPLICATION_CREDENTIALS`
- Confirm Vertex AI API is enabled: `gcloud services enable aiplatform.googleapis.com`
- Check service account has `roles/aiplatform.user` permission

### "Cloud Run deployment failed"
- Verify service account has `roles/run.admin` permission
- Check Docker image exists in Artifact Registry: `gcloud artifacts docker images list us-west1-docker.pkg.dev/PROJECT_ID/ats-analyzer`
- Review Cloud Run logs: `gcloud run services describe gcp-ats-analyzer-dev --region us-west1 --format=json | jq '.status'`

### "API returns 405 Method Not Allowed" (OPTIONS request fails)
- CORS middleware is required for browser-based API calls
- Ensure `fastapi.middleware.cors.CORSMiddleware` is added to app
- This is already configured in the latest version

### "PDF parsing fails in browser"
- Ensure PDF is text-based (not scanned/image-only)
- Max file size is 10MB
- Try with a simple test PDF first
- Check browser console for errors: **F12 → Console tab**

---

## What This Project Demonstrates

### Cloud DevOps Skills
✅ **GCP Infrastructure Management**
- Cloud Run serverless deployment
- Artifact Registry Docker image management  
- Service Account & IAM roles configuration
- API enablement and quota management

✅ **Infrastructure as Code (Terraform)**
- Resource declaration and dependency management
- Output variables for automation
- IAM policy management
- Multi-tier architecture setup

✅ **CI/CD Pipeline**
- GitHub Actions workflow automation
- Service account authentication
- Docker image building and registry push
- Automated deployments with zero-downtime updates

✅ **Production Readiness**
- Error handling and logging
- CORS middleware for cross-origin requests
- Health check endpoints
- Environment-based configuration
- Proper HTTP status codes (204 for no-content responses)

✅ **DevOps Best Practices**
- Containerization with Docker
- Stateless application design
- Infrastructure in Git (version control)
- Least privilege IAM permissions
- Cost optimization (free tier, scale-to-zero)

---

## Security Considerations

- **Service account**: Minimal permissions (principle of least privilege)
  - Only `roles/aiplatform.user`, `roles/logging.logWriter`, `roles/monitoring.metricWriter`
- **Cloud Run**: Scales to zero (no idle costs, reduced attack surface)
- **API authentication**: Vertex AI uses Application Default Credentials (ADC)
- **Frontend**: In-browser PDF parsing (no files sent to backend)
- **CORS**: Configured to allow same-origin requests for browser compatibility
- **Environment variables**: GCP credentials handled by Cloud Run service account (no key files needed)

---

## Development

Built with [Claude Code](https://claude.com/claude-code).

---

## Contributing

To add features or fixes:
1. Create a feature branch
2. Test locally with Docker
3. Push to `develop` branch for testing
4. Create a PR to `main` for deployment

---

