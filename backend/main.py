"""
Sherlock Backend - Main FastAPI Application

This is the main entry point for the Sherlock deepfake detection backend.
It configures the FastAPI application, sets up CORS for cross-origin requests,
and includes all API routes.

Architecture:
- FastAPI for REST API framework
- CORS middleware for Flutter app communication
- Structured routing with API versioning
- Global exception handling
- Request/response logging
"""

import os
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from loguru import logger
import time

from api.routes import detection, health
from core.config import settings
from core.exceptions import SherlockException

# Configure logging
logger.add(
    "logs/sherlock.log",
    rotation="1 day",
    retention="30 days",
    level="INFO",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level} | {name}:{function}:{line} | {message}"
)

# Create FastAPI application
app = FastAPI(
    title="Sherlock API",
    description="AI-Powered Deepfake Video Detection Backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# Add CORS middleware for Flutter app communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Add trusted host middleware for security
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=settings.ALLOWED_HOSTS
)

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests with timing information."""
    start_time = time.time()
    
    # Log request
    logger.info(f"Request: {request.method} {request.url.path}")
    
    # Process request
    response = await call_next(request)
    
    # Log response with timing
    process_time = time.time() - start_time
    logger.info(
        f"Response: {response.status_code} | "
        f"Time: {process_time:.3f}s | "
        f"Path: {request.url.path}"
    )
    
    return response

# Global exception handler
@app.exception_handler(SherlockException)
async def sherlock_exception_handler(request: Request, exc: SherlockException):
    """Handle custom Sherlock exceptions."""
    logger.error(f"Sherlock Exception: {exc.message} | Code: {exc.code}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.message,
            "code": exc.code,
            "detail": exc.detail
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle unexpected exceptions."""
    logger.error(f"Unexpected error: {str(exc)} | Path: {request.url.path}")
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "code": "INTERNAL_ERROR",
            "detail": "An unexpected error occurred while processing your request."
        }
    )

# Include API routes
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(detection.router, prefix="/api/v1", tags=["detection"])

@app.on_event("startup")
async def startup_event():
    """Initialize application on startup."""
    logger.info("🚀 Sherlock backend starting up...")
    logger.info(f"📊 Environment: {settings.ENVIRONMENT}")
    logger.info(f"🔍 Models directory: {settings.MODELS_DIR}")
    
    # Create necessary directories
    os.makedirs("logs", exist_ok=True)
    os.makedirs("uploads", exist_ok=True)
    os.makedirs("temp", exist_ok=True)
    
    # Initialize ML models (if needed)
    from core.model_manager import ModelManager
    model_manager = ModelManager()
    await model_manager.initialize()
    
    logger.info("✅ Sherlock backend startup complete!")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on application shutdown."""
    logger.info("🛑 Sherlock backend shutting down...")
    
    # Cleanup temporary files
    import shutil
    if os.path.exists("temp"):
        shutil.rmtree("temp")
    
    logger.info("✅ Sherlock backend shutdown complete!")

@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Welcome to Sherlock API",
        "version": "1.0.0",
        "description": "AI-Powered Deepfake Video Detection",
        "docs": "/docs",
        "health": "/api/v1/health"
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    ) 