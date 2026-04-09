import json
import logging
import os

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI
app = FastAPI(title="GCP ATS Analyzer")

# ============================================================================
# LLM Configuration (Vertex AI / Gemini)
# ============================================================================

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID", "").strip()
GCP_REGION = os.getenv("GCP_REGION", "us-central1").strip()

if not GCP_PROJECT_ID:
    logger.error("❌ Missing GCP_PROJECT_ID!")
    raise ValueError("GCP_PROJECT_ID is required")

try:
    import vertexai
    from vertexai.generative_models import GenerativeModel
    vertexai.init(project=GCP_PROJECT_ID, location=GCP_REGION)
    logger.info(f"✅ Vertex AI (Gemini) configured for project: {GCP_PROJECT_ID}, region: {GCP_REGION}")
except Exception as e:
    logger.error(f"❌ Failed to initialize Vertex AI: {str(e)}")
    raise ValueError(f"Vertex AI initialization failed: {str(e)}")


# ============================================================================
# Request/Response Models
# ============================================================================

class AnalyzeRequest(BaseModel):
    job_description: str
    resume_text: str


class AnalyzeResponse(BaseModel):
    ats_score: int
    matching_keywords: list[str]
    missing_keywords: list[str]
    actionable_feedback: str


# ============================================================================
# Helper Functions
# ============================================================================

def call_vertex_ai(job_description: str, resume_text: str) -> AnalyzeResponse:
    """
    Call Vertex AI (Gemini) to analyze resume vs job description.
    Returns structured ATS analysis.
    """
    from vertexai.generative_models import GenerativeModel

    system_prompt = (
        "You are an ATS evaluating Resume against Job Description.\n"
        "Output MUST be valid JSON with NO markdown, NO code fences, ONLY raw JSON.\n\n"
        "ANALYZE:\n"
        "1. What industry is the JD? What industry is the Resume?\n"
        "2. Same industry → proceed. Different industries → score max 25%.\n"
        "3. Extract MISSING keywords: top 10 most critical skills/certs in JD but absent from Resume.\n"
        "4. Extract MATCHING keywords: top 10 exact phrases that appear in BOTH JD and Resume.\n"
        "5. Score based on:\n"
        "   - 0-20%: Different industries OR missing critical certifications\n"
        "   - 21-50%: Same field, significant gaps\n"
        "   - 51-75%: Same field, minor gaps\n"
        "   - 76-100%: Strong match\n\n"
        "LIMITS (IMPORTANT):\n"
        "- matching_keywords: MAXIMUM 10 items. Stop at 10.\n"
        "- missing_keywords: MAXIMUM 10 items. Stop at 10.\n"
        "- actionable_feedback: Keep it SHORT (1-2 sentences max).\n"
        "- ONLY include exact word-for-word matches in matching_keywords\n"
        "- If no exact matches, matching_keywords = []\n\n"
        "OUTPUT FORMAT: Valid JSON object ONLY. No explanation. No markdown.\n"
        "Format: {\"ats_score\": <0-100>, \"matching_keywords\": [max 10], \"missing_keywords\": [max 10], \"actionable_feedback\": \"<short>\"}"
    )

    prompt = f"""{system_prompt}

JOB DESCRIPTION:
{job_description}

RESUME:
{resume_text}"""

    try:
        model = GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(prompt)
        response_text = response.text.strip()
        logger.debug(f"Vertex AI response: {response_text}")

        # Parse JSON from response
        # Handle cases where the model might include markdown code blocks
        if "```json" in response_text:
            response_text = response_text.split("```json")[1].split("```")[0].strip()
        elif "```" in response_text:
            response_text = response_text.split("```")[1].split("```")[0].strip()

        parsed_data = json.loads(response_text)

        # Validate and normalize response
        return AnalyzeResponse(
            ats_score=max(0, min(100, int(parsed_data.get("ats_score", 0)))),
            matching_keywords=parsed_data.get("matching_keywords", [])[:20],
            missing_keywords=parsed_data.get("missing_keywords", [])[:20],
            actionable_feedback=parsed_data.get("actionable_feedback", "No feedback available.")
        )
    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse Vertex AI response as JSON: {response_text}")
        raise HTTPException(status_code=500, detail=f"Invalid AI response format: {str(e)}")
    except Exception as e:
        logger.error(f"Vertex AI analysis failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"AI analysis failed: {str(e)}")


# ============================================================================
# API Endpoints
# ============================================================================

@app.post("/analyze", response_model=AnalyzeResponse)
async def analyze(request: AnalyzeRequest):
    """
    Main endpoint: analyze resume vs job description using Vertex AI (Gemini).
    """
    if not request.job_description.strip():
        raise HTTPException(status_code=400, detail="Job description cannot be empty")

    if not request.resume_text.strip():
        raise HTTPException(status_code=400, detail="Resume text cannot be empty")

    logger.info(f"Analyzing resume ({len(request.resume_text)} chars) against job description ({len(request.job_description)} chars)")

    result = call_vertex_ai(request.job_description, request.resume_text)

    logger.info(f"Analysis complete: score={result.ats_score}")

    return result


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": "gcp-ats-analyzer"}


# ============================================================================
# Static File Serving
# ============================================================================

# Mount static files (frontend SPA)
app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
async def read_index():
    """Serve index.html for root path (SPA fallback)."""
    return FileResponse("static/index.html")


@app.get("/favicon.ico")
async def favicon():
    """Favicon - return 204 No Content to suppress browser errors."""
    return Response(status_code=204)


@app.get("/{full_path:path}")
async def serve_spa(full_path: str):
    """
    SPA fallback: serve index.html for any unmatched routes.
    This allows client-side routing to work.
    """
    # Skip favicon requests
    if full_path == "favicon.ico":
        return Response(status_code=204)

    # If it looks like a static file, try to serve it
    if "." in full_path:
        try:
            return FileResponse(f"static/{full_path}")
        except:
            pass
    # Otherwise serve index.html for client-side routing
    return FileResponse("static/index.html")


# ============================================================================
# Startup
# ============================================================================

@app.on_event("startup")
async def startup():
    logger.info("🚀 GCP ATS Analyzer started")
    logger.info(f"✅ Using Vertex AI (Gemini) for project: {GCP_PROJECT_ID}")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
