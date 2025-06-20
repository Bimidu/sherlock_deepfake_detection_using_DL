"""
Model Manager for Sherlock Backend

This module manages the loading, initialization, and lifecycle of ML models
used for deepfake detection. It provides a centralized interface for model
operations and maintains model state across the application.
"""

import os
import asyncio
from typing import Dict, List, Any, Optional
from loguru import logger

from core.config import settings, get_model_config, get_model_path
from core.exceptions import ModelError, ModelNotFoundError
from models.base_detector import BaseDetector
from models.xception_detector import XceptionDetector
from models.mesonet_detector import MesoNetDetector


class ModelManager:
    """Centralized manager for deepfake detection models."""
    
    def __init__(self):
        """Initialize the model manager."""
        self.models: Dict[str, BaseDetector] = {}
        self.initialized = False
        self._lock = asyncio.Lock()
    
    async def initialize(self):
        """
        Initialize all available models.
        
        This method loads and prepares all configured models for inference.
        It's called during application startup.
        """
        if self.initialized:
            logger.info("Models already initialized")
            return
        
        async with self._lock:
            if self.initialized:  # Double-check after acquiring lock
                return
            
            logger.info("Initializing model manager...")
            
            try:
                # Initialize models defined in settings
                for model_name in settings.AVAILABLE_MODELS.keys():
                    logger.info(f"Loading model: {model_name}")
                    
                    try:
                        await self._load_model(model_name)
                        logger.success(f"Model {model_name} loaded successfully")
                    except Exception as e:
                        # Log but continue - don't fail entire initialization for one model
                        logger.error(f"Failed to load model {model_name}: {str(e)}")
                        continue
                
                if not self.models:
                    logger.warning("No models loaded successfully")
                else:
                    logger.success(f"Model manager initialized with {len(self.models)} models")
            except Exception as e:
                logger.error(f"Failed to initialize model manager: {str(e)}")
                raise ModelError(
                    "Failed to initialize model manager",
                    detail={"error": str(e)}
                )
    
    async def _load_model(self, model_name: str):
        """
        Load a specific model.
        
        Args:
            model_name: Name of the model to load
            
        Raises:
            ModelError: If model loading fails
        """
        try:
            config = get_model_config(model_name)
            model_path = get_model_path(model_name)
            
            # Create detector instance based on model type
            detector = self._create_detector(model_name, model_path, config)
            
            # Load the model
            await detector.load_model()
            
            # Store the loaded model
            self.models[model_name] = detector
            
            logger.debug(f"Loaded model {model_name} from {model_path}")
            
        except Exception as e:
            logger.error(f"Failed to load model {model_name}: {str(e)}")
            raise ModelError(f"Failed to load {model_name}: {str(e)}")
    
    def _create_detector(
        self,
        model_name: str,
        model_path: str,
        config: Dict[str, Any]
    ) -> BaseDetector:
        """
        Create a detector instance for the specified model.
        
        Args:
            model_name: Name of the model
            model_path: Path to the model file
            config: Model configuration
            
        Returns:
            Detector instance
            
        Raises:
            ModelError: If model type is unknown
        """
        if model_name == "xception":
            return XceptionDetector(model_path, config)
        elif model_name == "mesonet":
            return MesoNetDetector(model_path, config)
        else:
            raise ModelError(f"Unknown model type: {model_name}")
    
    def get_model(self, model_name: str) -> BaseDetector:
        """
        Get a loaded model by name.
        
        Args:
            model_name: Name of the model
            
        Returns:
            Model detector instance
            
        Raises:
            ModelNotFoundError: If model is not loaded
        """
        if model_name not in self.models:
            raise ModelNotFoundError(model_name)
        
        return self.models[model_name]
    
    def is_model_loaded(self, model_name: str) -> bool:
        """
        Check if a model is loaded.
        
        Args:
            model_name: Name of the model
            
        Returns:
            True if model is loaded, False otherwise
        """
        return model_name in self.models and self.models[model_name].is_loaded
    
    def get_loaded_models(self) -> List[str]:
        """
        Get list of loaded model names.
        
        Returns:
            List of loaded model names
        """
        return [
            name for name, detector in self.models.items()
            if detector.is_loaded
        ]
    
    def get_model_info(self, model_name: str) -> Dict[str, Any]:
        """
        Get information about a model.
        
        Args:
            model_name: Name of the model
            
        Returns:
            Model information dictionary
            
        Raises:
            ModelNotFoundError: If model is not found
        """
        if model_name not in settings.AVAILABLE_MODELS:
            raise ModelNotFoundError(model_name)
        
        config = get_model_config(model_name)
        model_path = get_model_path(model_name)
        is_loaded = self.is_model_loaded(model_name)
        is_available = os.path.exists(model_path)
        
        info = {
            "name": model_name,
            "display_name": config["name"],
            "description": config["description"],
            "input_size": config["input_size"],
            "preprocessing": config["preprocessing"],
            "file_path": model_path,
            "is_loaded": is_loaded,
            "is_available": is_available,
            "is_default": model_name == settings.DEFAULT_MODEL
        }
        
        # Add runtime info if model is loaded
        if is_loaded:
            detector = self.models[model_name]
            info.update(detector.get_model_info())
        
        return info
    
    def get_all_models_info(self) -> List[Dict[str, Any]]:
        """
        Get information about all configured models.
        
        Returns:
            List of model information dictionaries
        """
        models_info = []
        
        for model_name in settings.AVAILABLE_MODELS.keys():
            try:
                info = self.get_model_info(model_name)
                models_info.append(info)
            except Exception as e:
                logger.error(f"Error getting info for model {model_name}: {str(e)}")
                # Add basic error info
                models_info.append({
                    "name": model_name,
                    "display_name": model_name,
                    "description": "Error loading model info",
                    "is_loaded": False,
                    "is_available": False,
                    "error": str(e)
                })
        
        return models_info
    
    async def reload_model(self, model_name: str):
        """
        Reload a specific model.
        
        Args:
            model_name: Name of the model to reload
            
        Raises:
            ModelNotFoundError: If model is not configured
        """
        if model_name not in settings.AVAILABLE_MODELS:
            raise ModelNotFoundError(model_name)
        
        async with self._lock:
            # Remove existing model if loaded
            if model_name in self.models:
                del self.models[model_name]
                logger.info(f"Removed existing model: {model_name}")
            
            # Load the model again
            await self._load_model(model_name)
            logger.info(f"Reloaded model: {model_name}")
    
    def get_default_model(self) -> str:
        """
        Get the default model name.
        
        Returns:
            Default model name
            
        Raises:
            ModelError: If no models are available
        """
        # First try the configured default
        if self.is_model_loaded(settings.DEFAULT_MODEL):
            return settings.DEFAULT_MODEL
        
        # Fallback to any loaded model
        loaded_models = self.get_loaded_models()
        if loaded_models:
            return loaded_models[0]
        
        raise ModelError("No models are currently loaded")
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about model manager state.
        
        Returns:
            Statistics dictionary
        """
        total_models = len(settings.AVAILABLE_MODELS)
        loaded_models = len(self.get_loaded_models())
        
        return {
            "total_configured": total_models,
            "loaded": loaded_models,
            "load_rate": loaded_models / total_models * 100 if total_models > 0 else 0,
            "default_model": settings.DEFAULT_MODEL,
            "initialized": self.initialized,
            "loaded_models": self.get_loaded_models()
        } 