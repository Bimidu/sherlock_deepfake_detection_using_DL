"""
Video Detection API Routes

This module handles video upload, processing, and deepfake detection.
Main endpoints for the Flutter app to interact with the backend.
"""

import os
import uuid
import asyncio
from datetime import datetime
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, File, UploadFile, HTTPException, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from loguru import logger

from core.config import settings
from core.exceptions import (
    FileUploadError, VideoProcessingError, TaskNotFoundError,
    ValidationError, ResourceLimitError
)
from services.video_processor import VideoProcessor
from services.detection_service import DetectionService
from services.task_manager import TaskManager
from utils.file_validator import FileValidator

router = APIRouter()

# Initialize services
video_processor = VideoProcessor()
detection_service = DetectionService()
task_manager = TaskManager()
file_validator = FileValidator()


@router.post("/upload")
async def upload_video(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    model_name: Optional[str] = Query(default=settings.DEFAULT_MODEL, description="Model to use for detection")
) -> Dict[str, Any]:
    """
    Upload a video file for deepfake detection analysis.
    
    This endpoint:
    1. Validates the uploaded file
    2. Saves it temporarily
    3. Creates a background task for processing
    4. Returns a task ID for status tracking
    
    Args:
        file: Video file to analyze
        model_name: ML model to use for detection
        
    Returns:
        Dictionary with task_id and upload status
        
    Raises:
        FileUploadError: If file validation fails
        ResourceLimitError: If system resources are exceeded
    """
    logger.info(f"🎬 Video upload started: {file.filename}")
    
    try:
        # Validate file
        await file_validator.validate_video_file(file)
        
        # Check system resources
        active_tasks = await task_manager.get_active_task_count()
        if active_tasks >= settings.MAX_CONCURRENT_TASKS:
            raise ResourceLimitError(
                f"Maximum concurrent tasks ({settings.MAX_CONCURRENT_TASKS}) exceeded. Please try again later."
            )
        
        # Generate unique task ID
        task_id = str(uuid.uuid4())
        
        # Save uploaded file
        file_path = await _save_uploaded_file(file, task_id)
        
        # Create task record
        task_data = {
            "task_id": task_id,
            "filename": file.filename,
            "file_path": file_path,
            "model_name": model_name,
            "status": "uploaded",
            "created_at": datetime.utcnow().isoformat(),
            "progress": 0
        }
        
        await task_manager.create_task(task_id, task_data)
        
        # Start background processing
        background_tasks.add_task(
            _process_video_background,
            task_id,
            file_path,
            model_name
        )
        
        logger.info(f"✅ Video uploaded successfully: {task_id}")
        
        return {
            "success": True,
            "task_id": task_id,
            "message": "Video uploaded successfully. Processing started.",
            "filename": file.filename,
            "model": model_name,
            "status_url": f"/api/v1/results/{task_id}"
        }
        
    except Exception as e:
        logger.error(f"❌ Upload failed: {str(e)}")
        if isinstance(e, (FileUploadError, ValidationError, ResourceLimitError)):
            raise e
        raise FileUploadError(f"Upload failed: {str(e)}")


@router.get("/results/{task_id}")
async def get_detection_results(task_id: str) -> Dict[str, Any]:
    """
    Get detection results for a specific task.
    
    Args:
        task_id: Unique task identifier
        
    Returns:
        Dictionary containing task status and results
        
    Raises:
        TaskNotFoundError: If task ID is not found
    """
    logger.info(f"📊 Fetching results for task: {task_id}")
    
    try:
        task_data = await task_manager.get_task(task_id)
        
        if not task_data:
            raise TaskNotFoundError(task_id)
        
        return {
            "task_id": task_id,
            "status": task_data.get("status", "unknown"),
            "progress": task_data.get("progress", 0),
            "created_at": task_data.get("created_at"),
            "completed_at": task_data.get("completed_at"),
            "filename": task_data.get("filename"),
            "model_used": task_data.get("model_name"),
            "results": task_data.get("results"),
            "error": task_data.get("error")
        }
        
    except TaskNotFoundError:
        raise
    except Exception as e:
        logger.error(f"❌ Error fetching results: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error fetching results: {str(e)}")


@router.get("/tasks")
async def list_tasks(
    limit: int = Query(default=10, ge=1, le=100),
    offset: int = Query(default=0, ge=0)
) -> Dict[str, Any]:
    """
    List recent tasks with pagination.
    
    Args:
        limit: Maximum number of tasks to return
        offset: Number of tasks to skip
        
    Returns:
        Dictionary containing list of tasks and pagination info
    """
    try:
        tasks = await task_manager.list_tasks(limit=limit, offset=offset)
        total_count = await task_manager.get_total_task_count()
        
        return {
            "tasks": tasks,
            "pagination": {
                "limit": limit,
                "offset": offset,
                "total": total_count,
                "has_more": offset + limit < total_count
            }
        }
        
    except Exception as e:
        logger.error(f"❌ Error listing tasks: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing tasks: {str(e)}")


@router.delete("/tasks/{task_id}")
async def delete_task(task_id: str) -> Dict[str, Any]:
    """
    Delete a task and its associated files.
    
    Args:
        task_id: Unique task identifier
        
    Returns:
        Success confirmation
        
    Raises:
        TaskNotFoundError: If task ID is not found
    """
    logger.info(f"🗑️ Deleting task: {task_id}")
    
    try:
        task_data = await task_manager.get_task(task_id)
        
        if not task_data:
            raise TaskNotFoundError(task_id)
        
        # Clean up files
        file_path = task_data.get("file_path")
        if file_path and os.path.exists(file_path):
            os.remove(file_path)
        
        # Delete task record
        await task_manager.delete_task(task_id)
        
        logger.info(f"✅ Task deleted successfully: {task_id}")
        
        return {
            "success": True,
            "message": f"Task {task_id} deleted successfully"
        }
        
    except TaskNotFoundError:
        raise
    except Exception as e:
        logger.error(f"❌ Error deleting task: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting task: {str(e)}")


@router.get("/models")
async def list_available_models() -> Dict[str, Any]:
    """
    List all available detection models.
    
    Returns:
        Dictionary containing available models and their info
    """
    try:
        models = []
        for model_name, config in settings.AVAILABLE_MODELS.items():
            model_path = os.path.join(settings.MODELS_DIR, config["file"])
            is_available = os.path.exists(model_path)
            
            models.append({
                "name": model_name,
                "display_name": config["name"],
                "description": config["description"],
                "input_size": config["input_size"],
                "preprocessing": config["preprocessing"],
                "available": is_available,
                "is_default": model_name == settings.DEFAULT_MODEL
            })
        
        return {
            "models": models,
            "default_model": settings.DEFAULT_MODEL,
            "total_count": len(models)
        }
        
    except Exception as e:
        logger.error(f"❌ Error listing models: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error listing models: {str(e)}")


async def _save_uploaded_file(file: UploadFile, task_id: str) -> str:
    """
    Save uploaded file to disk.
    
    Args:
        file: Uploaded file object
        task_id: Unique task identifier
        
    Returns:
        Path to saved file
    """
    # Create unique filename
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{task_id}{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIR, filename)
    
    # Save file
    with open(file_path, "wb") as buffer:
        content = await file.read()
        buffer.write(content)
    
    logger.info(f"💾 File saved: {file_path}")
    return file_path


async def _process_video_background(task_id: str, file_path: str, model_name: str):
    """
    Background task for video processing and detection.
    
    Args:
        task_id: Unique task identifier
        file_path: Path to uploaded video file
        model_name: Model to use for detection
    """
    logger.info(f"🔍 Starting background processing for task: {task_id}")
    
    try:
        # Update task status
        await task_manager.update_task_status(task_id, "processing", progress=10)
        
        # Extract frames from video
        logger.info(f"📽️ Extracting frames from video: {file_path}")
        frames_data = await video_processor.extract_frames(file_path)
        await task_manager.update_task_status(task_id, "processing", progress=40)
        
        # Run detection on frames
        logger.info(f"🤖 Running detection with model: {model_name}")
        detection_results = await detection_service.detect_deepfake(
            frames_data, model_name
        )
        await task_manager.update_task_status(task_id, "processing", progress=80)
        
        # Aggregate results
        final_results = await detection_service.aggregate_results(detection_results)
        await task_manager.update_task_status(task_id, "processing", progress=95)
        
        # Update task with final results
        await task_manager.complete_task(task_id, final_results)
        
        logger.info(f"✅ Processing completed for task: {task_id}")
        
    except Exception as e:
        logger.error(f"❌ Processing failed for task {task_id}: {str(e)}")
        await task_manager.fail_task(task_id, str(e))
    
    finally:
        # Clean up uploaded file
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.info(f"🧹 Cleaned up file: {file_path}") 