"""
Configuration Settings for Sherlock Backend

This module contains all configuration settings for the application,
including environment variables, file paths, model settings, and API configuration.
Uses Pydantic for type validation and environment variable loading.
"""

import os
from typing import List, Optional
from pydantic_settings import BaseSettings
from pydantic import validator


class Settings(BaseSettings):
    """Application settings with environment variable support."""
    
    # Application settings
    APP_NAME: str = "Sherlock API"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    
    # API Configuration
    API_V1_STR: str = "/api/v1"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # CORS settings - Important for Flutter app communication
    ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8080",
        "*"  # Allow all origins in development (restrict in production)
    ]
    
    ALLOWED_HOSTS: List[str] = [
        "localhost",
        "127.0.0.1",
        "*"  # Allow all hosts in development
    ]
    
    # File upload settings
    MAX_FILE_SIZE: int = 100 * 1024 * 1024  # 100MB max file size
    ALLOWED_VIDEO_EXTENSIONS: List[str] = [
        ".mp4", ".avi", ".mov", ".mkv", ".flv", ".wmv", ".webm"
    ]
    
    # Directory paths
    BASE_DIR: str = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    UPLOAD_DIR: str = os.path.join(BASE_DIR, "uploads")
    TEMP_DIR: str = os.path.join(BASE_DIR, "temp")
    MODELS_DIR: str = os.path.join(BASE_DIR, "models")
    LOGS_DIR: str = os.path.join(BASE_DIR, "logs")
    
    # Video processing settings
    FRAME_EXTRACTION_RATE: int = 1  # Extract 1 frame per second
    MAX_FRAMES_PER_VIDEO: int = 300  # Limit frames for performance
    VIDEO_RESOLUTION: tuple = (224, 224)  # Standard input size for models
    
    # Model settings
    DEFAULT_MODEL: str = "xception"  # Default model to use
    MODEL_CONFIDENCE_THRESHOLD: float = 0.5  # Threshold for classification
    BATCH_SIZE: int = 32  # Batch size for inference
    
    # Available models configuration
    AVAILABLE_MODELS: dict = {
        "xception": {
            "name": "XceptionNet",
            "description": "High accuracy deepfake detection model",
            "file": "xception_deepfake_detector.pth",
            "input_size": (224, 224),
            "preprocessing": "imagenet"
        },
        "mesonet": {
            "name": "MesoNet",
            "description": "Lightweight model for real-time inference",
            "file": "mesonet_deepfake_detector.pth",
            "input_size": (256, 256),
            "preprocessing": "custom"
        }
    }
    
    # Security settings
    SECRET_KEY: str = "your-secret-key-change-in-production"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    API_KEY: Optional[str] = None  # Optional API key for authentication
    
    # Logging settings
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "{time:YYYY-MM-DD HH:mm:ss} | {level} | {name}:{function}:{line} | {message}"
    
    # Performance settings
    WORKERS: int = 4  # Number of worker processes for production
    MAX_CONCURRENT_TASKS: int = 10  # Maximum concurrent video processing tasks
    
    # Database settings (if needed for task tracking)
    DATABASE_URL: Optional[str] = None
    
    @validator('ALLOWED_ORIGINS', pre=True)
    def assemble_cors_origins(cls, v):
        """Parse CORS origins from environment variable or use defaults."""
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",")]
        return v
    
    @validator('MODELS_DIR', pre=True)
    def create_models_dir(cls, v):
        """Ensure models directory exists."""
        os.makedirs(v, exist_ok=True)
        return v
    
    @validator('UPLOAD_DIR', pre=True)
    def create_upload_dir(cls, v):
        """Ensure upload directory exists."""
        os.makedirs(v, exist_ok=True)
        return v
    
    @validator('TEMP_DIR', pre=True)
    def create_temp_dir(cls, v):
        """Ensure temporary directory exists."""
        os.makedirs(v, exist_ok=True)
        return v
    
    @validator('LOGS_DIR', pre=True)
    def create_logs_dir(cls, v):
        """Ensure logs directory exists."""
        os.makedirs(v, exist_ok=True)
        return v
    
    class Config:
        """Pydantic configuration."""
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Create global settings instance
settings = Settings()


def get_model_config(model_name: str) -> dict:
    """
    Get configuration for a specific model.
    
    Args:
        model_name: Name of the model
        
    Returns:
        Model configuration dictionary
        
    Raises:
        ValueError: If model is not available
    """
    if model_name not in settings.AVAILABLE_MODELS:
        available = list(settings.AVAILABLE_MODELS.keys())
        raise ValueError(f"Model '{model_name}' not available. Available models: {available}")
    
    return settings.AVAILABLE_MODELS[model_name]


def get_model_path(model_name: str) -> str:
    """
    Get the full path to a model file.
    
    Args:
        model_name: Name of the model
        
    Returns:
        Full path to the model file
    """
    model_config = get_model_config(model_name)
    return os.path.join(settings.MODELS_DIR, model_config["file"]) 