#!/bin/bash

# Local Development Startup Script
# Brings up both frontend and backend for Phase 1 testing

set -e

echo "🚀 GCP ATS Analyzer - Local Development Setup"
echo "=============================================="
echo ""

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker Desktop."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "⚠️  docker-compose not found, trying 'docker compose'..."
    if ! docker compose version &> /dev/null; then
        echo "❌ Docker Compose is not available."
        exit 1
    fi
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "✅ Docker environment ready"
echo ""

# Check which LLM backend will be used
if [ -n "$LOCAL_LLM_ENDPOINT" ] && [ -n "$LOCAL_LLM_MODEL" ]; then
    echo "✅ Local LLM configured:"
    echo "   Endpoint: $LOCAL_LLM_ENDPOINT"
    echo "   Model: $LOCAL_LLM_MODEL"
    echo ""
elif [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "✅ GCP credentials found at: $GOOGLE_APPLICATION_CREDENTIALS"
    echo "   Vertex AI API calls will use real GCP project"
    echo ""
else
    echo "⚠️  No LLM backend configured"
    echo "   Analysis will fail without one of the following:"
    echo ""
    echo "   Option 1 - Local LLM (recommended for testing):"
    echo "   export LOCAL_LLM_ENDPOINT=http://10.0.0.95:1234/v1/chat/completions"
    echo "   export LOCAL_LLM_MODEL=HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive"
    echo ""
    echo "   Option 2 - Vertex AI:"
    echo "   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json"
    echo "   export GCP_PROJECT_ID=your-project-id"
    echo "   export GCP_REGION=us-central1"
    echo ""
fi

# Stop any existing containers
echo "Cleaning up existing containers..."
$COMPOSE_CMD down 2>/dev/null || true
echo ""

# Start services
echo "📦 Building and starting services..."
$COMPOSE_CMD up

# Cleanup on exit
trap "$COMPOSE_CMD down" EXIT
