"""
Health Check API Routes

This module provides health check endpoints for monitoring the
application status, dependencies, and system resources.
"""

import psutil
import time
from datetime import datetime
from fastapi import APIRouter, Depends
from typing import Dict, Any

from core.config import settings

router = APIRouter()


@router.get("/health")
async def health_check() -> Dict[str, Any]:
    """
    Basic health check endpoint.
    
    Returns:
        Dictionary containing basic health status
    """
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT
    }


@router.get("/health/detailed")
async def detailed_health_check() -> Dict[str, Any]:
    """
    Detailed health check with system metrics.
    
    Returns:
        Dictionary containing detailed system information
    """
    # Get system metrics
    cpu_percent = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    disk = psutil.disk_usage('/')
    
    # Check if models directory exists and has models
    import os
    models_available = []
    if os.path.exists(settings.MODELS_DIR):
        for model_name, config in settings.AVAILABLE_MODELS.items():
            model_path = os.path.join(settings.MODELS_DIR, config["file"])
            models_available.append({
                "name": model_name,
                "description": config["description"],
                "available": os.path.exists(model_path),
                "path": model_path
            })
    
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
        "system": {
            "cpu_percent": cpu_percent,
            "memory": {
                "total": memory.total,
                "available": memory.available,
                "percent": memory.percent,
                "used": memory.used
            },
            "disk": {
                "total": disk.total,
                "free": disk.free,
                "percent": (disk.used / disk.total) * 100
            }
        },
        "configuration": {
            "max_file_size": settings.MAX_FILE_SIZE,
            "allowed_extensions": settings.ALLOWED_VIDEO_EXTENSIONS,
            "frame_extraction_rate": settings.FRAME_EXTRACTION_RATE,
            "max_frames_per_video": settings.MAX_FRAMES_PER_VIDEO,
            "default_model": settings.DEFAULT_MODEL
        },
        "models": models_available,
        "directories": {
            "upload_dir": settings.UPLOAD_DIR,
            "temp_dir": settings.TEMP_DIR,
            "models_dir": settings.MODELS_DIR,
            "logs_dir": settings.LOGS_DIR
        }
    }


@router.get("/health/ready")
async def readiness_check() -> Dict[str, Any]:
    """
    Readiness check - verifies if the service is ready to handle requests.
    
    Returns:
        Dictionary indicating if service is ready
    """
    checks = []
    overall_status = "ready"
    
    # Check if essential directories exist
    directories = [
        ("upload_dir", settings.UPLOAD_DIR),
        ("temp_dir", settings.TEMP_DIR),
        ("models_dir", settings.MODELS_DIR),
        ("logs_dir", settings.LOGS_DIR)
    ]
    
    for name, path in directories:
        import os
        exists = os.path.exists(path)
        checks.append({
            "name": f"{name}_exists",
            "status": "pass" if exists else "fail",
            "message": f"Directory {path} {'exists' if exists else 'missing'}"
        })
        if not exists:
            overall_status = "not_ready"
    
    # Check if at least one model is available
    available_models = 0
    for model_name, config in settings.AVAILABLE_MODELS.items():
        model_path = os.path.join(settings.MODELS_DIR, config["file"])
        if os.path.exists(model_path):
            available_models += 1
    
    model_check = available_models > 0
    checks.append({
        "name": "models_available",
        "status": "pass" if model_check else "warn",
        "message": f"{available_models} models available"
    })
    
    # Note: We don't fail readiness if no models are available in development
    # but it's marked as a warning
    
    return {
        "status": overall_status,
        "timestamp": datetime.utcnow().isoformat(),
        "checks": checks
    }


@router.get("/health/live")
async def liveness_check() -> Dict[str, str]:
    """
    Liveness check - simple endpoint to verify the service is alive.
    
    Returns:
        Simple status message
    """
    return {
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat()
    } 