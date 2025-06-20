"""
Base Detector Class for Deepfake Detection Models

This module defines the base interface that all detection models must implement.
It provides a common interface for loading models, running inference, and
getting predictions in a consistent format.
"""

from abc import ABC, abstractmethod
import numpy as np
from typing import List, Tuple, Dict, Any
from loguru import logger


class BaseDetector(ABC):
    """
    Abstract base class for deepfake detection models.
    
    All detection models should inherit from this class and implement
    the required abstract methods.
    """
    
    def __init__(self, model_path: str, config: Dict[str, Any]):
        """
        Initialize the detector.
        
        Args:
            model_path: Path to the model file
            config: Model configuration dictionary
        """
        self.model_path = model_path
        self.config = config
        self.model = None
        self.is_loaded = False
        
        # Extract configuration
        self.name = config.get("name", "Unknown Model")
        self.description = config.get("description", "")
        self.input_size = config.get("input_size", (224, 224))
        self.preprocessing = config.get("preprocessing", "imagenet")
    
    @abstractmethod
    async def load_model(self):
        """
        Load the model from disk.
        
        This method should:
        1. Load the model weights from self.model_path
        2. Initialize the model architecture
        3. Set self.is_loaded = True on success
        
        Raises:
            ModelError: If model loading fails
        """
        pass
    
    @abstractmethod
    def predict(self, frames: np.ndarray) -> List[Tuple[float, float]]:
        """
        Run prediction on a batch of frames.
        
        Args:
            frames: Numpy array of shape (batch_size, height, width, channels)
                   with preprocessed frames
        
        Returns:
            List of (prediction, confidence) tuples where:
            - prediction: Float between 0-1 (probability of being fake)
            - confidence: Float between 0-1 (model confidence in prediction)
        
        Raises:
            InferenceError: If prediction fails
        """
        pass
    
    @abstractmethod
    def preprocess_frames(self, frames: np.ndarray) -> np.ndarray:
        """
        Preprocess frames for model input.
        
        Args:
            frames: Raw frames array
            
        Returns:
            Preprocessed frames ready for model input
        """
        pass
    
    def get_model_info(self) -> Dict[str, Any]:
        """
        Get information about the model.
        
        Returns:
            Dictionary containing model metadata
        """
        return {
            "name": self.name,
            "description": self.description,
            "input_size": self.input_size,
            "preprocessing": self.preprocessing,
            "model_path": self.model_path,
            "is_loaded": self.is_loaded
        }
    
    def validate_input(self, frames: np.ndarray) -> bool:
        """
        Validate input frames format.
        
        Args:
            frames: Input frames array
            
        Returns:
            True if valid, False otherwise
        """
        if not isinstance(frames, np.ndarray):
            logger.error("Input must be a numpy array")
            return False
        
        if len(frames.shape) != 4:
            logger.error(f"Expected 4D array (batch, height, width, channels), got {frames.shape}")
            return False
        
        batch_size, height, width, channels = frames.shape
        expected_height, expected_width = self.input_size
        
        if height != expected_height or width != expected_width:
            logger.error(f"Expected size {self.input_size}, got {(height, width)}")
            return False
        
        if channels != 3:
            logger.error(f"Expected 3 channels (RGB), got {channels}")
            return False
        
        return True
    
    def __str__(self) -> str:
        """String representation of the detector."""
        return f"{self.name} ({'loaded' if self.is_loaded else 'not loaded'})"
    
    def __repr__(self) -> str:
        """Detailed string representation."""
        return (
            f"BaseDetector(name='{self.name}', "
            f"input_size={self.input_size}, "
            f"is_loaded={self.is_loaded})"
        ) 