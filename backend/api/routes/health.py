"""
Health Check API Routes

This module provides health check endpoints for monitoring the
application status, dependencies, and system resources.
"""

import psutil
import time
from datetime import datetime
from fastapi import APIRouter, Depends, Query, HTTPException
from typing import Dict, Any, List
import os
from loguru import logger

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
    
    # Check if required directories exist
    directories_status = {}
    for dir_name, dir_path in [
        ("uploads", settings.UPLOAD_DIR),
        ("models", settings.MODELS_DIR),
        ("logs", settings.LOGS_DIR),
        ("temp", settings.TEMP_DIR)
    ]:
        directories_status[dir_name] = {
            "exists": os.path.exists(dir_path),
            "path": dir_path
        }
    
    # Check if log file exists and get basic info
    log_file_path = os.path.join(settings.LOGS_DIR, "sherlock.log")
    log_status = {
        "exists": os.path.exists(log_file_path),
        "path": log_file_path,
        "size": os.path.getsize(log_file_path) if os.path.exists(log_file_path) else 0
    }
    
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
            "default_model": settings.DEFAULT_MODEL,
            "max_concurrent_tasks": settings.MAX_CONCURRENT_TASKS
        },
        "models": models_available,
        "directories": directories_status,
        "log_file": log_status,
        "available_models": list(settings.AVAILABLE_MODELS.keys())
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


@router.get("/logs")
async def get_logs(
    limit: int = Query(default=100, ge=1, le=1000, description="Number of log entries to return"),
    level: str = Query(default="INFO", description="Minimum log level (DEBUG, INFO, WARNING, ERROR)")
) -> Dict[str, Any]:
    """
    Get recent backend logs for debugging and monitoring.
    
    Args:
        limit: Maximum number of log entries to return
        level: Minimum log level to include
        
    Returns:
        Dictionary containing log entries
    """
    try:
        log_file_path = os.path.join(settings.LOGS_DIR, "sherlock.log")
        
        if not os.path.exists(log_file_path):
            return {
                "logs": [],
                "total_entries": 0,
                "message": "Log file not found"
            }
        
        # Read the log file
        logs = []
        with open(log_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        # Parse recent log entries (get last 'limit' lines)
        recent_lines = lines[-limit:] if len(lines) > limit else lines
        
        for line in recent_lines:
            line = line.strip()
            if line:
                # Simple log parsing - in production you might want more sophisticated parsing
                logs.append({
                    "timestamp": line.split(" | ")[0] if " | " in line else "",
                    "level": line.split(" | ")[1] if " | " in line and len(line.split(" | ")) > 1 else "INFO",
                    "message": " | ".join(line.split(" | ")[3:]) if " | " in line and len(line.split(" | ")) > 3 else line
                })
        
        return {
            "logs": logs,
            "total_entries": len(logs),
            "log_file_size": os.path.getsize(log_file_path),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to read logs: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to read logs: {str(e)}")


@router.get("/version")
async def get_version() -> Dict[str, str]:
    """
    Get application version information.
    
    Returns:
        Dictionary with version info
    """
    return {
        "version": "1.0.0",
        "api_version": settings.API_V1_STR,
        "environment": settings.ENVIRONMENT
    } 