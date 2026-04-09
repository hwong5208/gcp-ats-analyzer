@echo off
REM Local Development Startup Script for Windows
REM Brings up both frontend and backend for Phase 1 testing

setlocal enabledelayedexpansion

echo.
echo 🚀 GCP ATS Analyzer - Local Development Setup
echo ==============================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker Desktop.
    pause
    exit /b 1
)

echo ✅ Docker environment ready
echo.

REM Check for GCP credentials
if defined GOOGLE_APPLICATION_CREDENTIALS (
    if exist "%GOOGLE_APPLICATION_CREDENTIALS%" (
        echo ✅ GCP credentials found at: %GOOGLE_APPLICATION_CREDENTIALS%
        echo    Vertex AI API calls will use real GCP project
        echo.
    ) else (
        echo ⚠️  GCP_APPLICATION_CREDENTIALS is set but file not found
        echo    Vertex AI API calls may fail
        echo.
    )
) else (
    echo ⚠️  No GCP credentials detected
    echo    Vertex AI API calls may fail (but frontend will still work^)
    echo    To use real Vertex AI:
    echo    1. Set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\service-account-key.json
    echo    2. Set GCP_PROJECT_ID and GCP_REGION
    echo.
)

REM Stop any existing containers
echo Cleaning up existing containers...
docker-compose down 2>nul

REM Start services
echo.
echo 📦 Building and starting services...
docker-compose up

pause
