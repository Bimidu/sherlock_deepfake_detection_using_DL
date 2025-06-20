"""
Custom Exception Classes for Sherlock Backend

This module defines custom exceptions used throughout the application
for better error handling and user feedback.
"""

from typing import Optional


class SherlockException(Exception):
    """Base exception class for Sherlock application."""
    
    def __init__(
        self,
        message: str,
        status_code: int = 500,
        code: str = "SHERLOCK_ERROR",
        detail: Optional[str] = None
    ):
        self.message = message
        self.status_code = status_code
        self.code = code
        self.detail = detail
        super().__init__(self.message)


class ValidationError(SherlockException):
    """Raised when input validation fails."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=400,
            code="VALIDATION_ERROR",
            detail=detail
        )


class FileUploadError(SherlockException):
    """Raised when file upload fails."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=400,
            code="FILE_UPLOAD_ERROR",
            detail=detail
        )


class VideoProcessingError(SherlockException):
    """Raised when video processing fails."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=422,
            code="VIDEO_PROCESSING_ERROR",
            detail=detail
        )


class ModelError(SherlockException):
    """Raised when ML model operations fail."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=500,
            code="MODEL_ERROR",
            detail=detail
        )


class ModelNotFoundError(SherlockException):
    """Raised when requested model is not found."""
    
    def __init__(self, model_name: str):
        super().__init__(
            message=f"Model '{model_name}' not found",
            status_code=404,
            code="MODEL_NOT_FOUND",
            detail=f"The requested model '{model_name}' is not available or not loaded"
        )


class InferenceError(SherlockException):
    """Raised when model inference fails."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=500,
            code="INFERENCE_ERROR",
            detail=detail
        )


class TaskNotFoundError(SherlockException):
    """Raised when task ID is not found."""
    
    def __init__(self, task_id: str):
        super().__init__(
            message=f"Task '{task_id}' not found",
            status_code=404,
            code="TASK_NOT_FOUND",
            detail=f"No task found with ID: {task_id}"
        )


class ResourceLimitError(SherlockException):
    """Raised when resource limits are exceeded."""
    
    def __init__(self, message: str, detail: Optional[str] = None):
        super().__init__(
            message=message,
            status_code=429,
            code="RESOURCE_LIMIT_ERROR",
            detail=detail
        ) 