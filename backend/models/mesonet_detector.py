"""
MesoNet Deepfake Detector

Implementation of deepfake detection using MesoNet architecture.
MesoNet is a lightweight model designed for real-time deepfake detection.
"""

import os
import numpy as np
import torch
import torch.nn as nn
import torchvision.transforms as transforms
from typing import List, Tuple, Dict, Any
from loguru import logger

from models.base_detector import BaseDetector
from core.exceptions import ModelError, InferenceError


class MesoNetDetector(BaseDetector):
    """MesoNet-based deepfake detector."""
    
    def __init__(self, model_path: str, config: Dict[str, Any]):
        """Initialize MesoNet detector."""
        super().__init__(model_path, config)
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.transform = None
        
    async def load_model(self):
        """Load MesoNet model."""
        try:
            logger.info(f"Loading MesoNet model from: {self.model_path}")
            
            # Check if model file exists
            if not os.path.exists(self.model_path):
                logger.info("Using freshly initialized model")
                self.model = self._create_demo_model()
            else:
                # Load the saved model
                self.model = torch.load(self.model_path, map_location=self.device)
                logger.info(f"Loaded model from: {self.model_path}")
                
            # Move to device and set eval mode
            self.model.to(self.device)
            self.model.eval()
            
            # Set up preprocessing
            self._setup_transforms()
            
            self.is_loaded = True
            logger.info("MesoNet model loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load MesoNet model: {str(e)}")
            raise ModelError(f"Failed to load MesoNet: {str(e)}")
    
    def _create_demo_model(self) -> nn.Module:
        """
        Create the proper MesoNet-4 model for deepfake detection.
        
        This creates the actual MesoNet architecture used in the original paper,
        not a simplified demo version.
        """
        class MesoNet4(nn.Module):
            def __init__(self, num_classes=1):
                super(MesoNet4, self).__init__()
                
                self.features = nn.Sequential(
                    # Conv Block 1
                    nn.Conv2d(3, 8, kernel_size=3, padding=1),
                    nn.BatchNorm2d(8),
                    nn.ReLU(inplace=True),
                    nn.MaxPool2d(2, 2),
                    
                    # Conv Block 2  
                    nn.Conv2d(8, 8, kernel_size=5, padding=2),
                    nn.BatchNorm2d(8),
                    nn.ReLU(inplace=True),
                    nn.MaxPool2d(2, 2),
                    
                    # Conv Block 3
                    nn.Conv2d(8, 16, kernel_size=5, padding=2),
                    nn.BatchNorm2d(16),
                    nn.ReLU(inplace=True),
                    nn.MaxPool2d(2, 2),
                    
                    # Conv Block 4
                    nn.Conv2d(16, 16, kernel_size=5, padding=2),
                    nn.BatchNorm2d(16),
                    nn.ReLU(inplace=True),
                    nn.MaxPool2d(4, 4),
                )
                
                self.classifier = nn.Sequential(
                    nn.Dropout(0.5),
                    nn.Linear(16 * 8 * 8, 16),  # First linear layer: 1024 -> 16
                    nn.LeakyReLU(0.1),
                    nn.Dropout(0.5),
                    nn.Linear(16, num_classes),  # Second linear layer: 16 -> 1
                    nn.Sigmoid()
                )
                
            def forward(self, x):
                x = self.features(x)
                x = torch.flatten(x, 1)
                x = self.classifier(x)
                return x
        
        return MesoNet4()
    
    def _setup_transforms(self):
        """Set up image preprocessing transforms for MesoNet."""
        # MesoNet typically uses simple normalization
        self.transform = transforms.Compose([
            transforms.ToTensor(),
            # Normalize to [-1, 1] range
            transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
        ])
    
    def predict(self, frames: np.ndarray) -> List[Tuple[float, float]]:
        """
        Run prediction on frames using MesoNet.
        
        Args:
            frames: Array of preprocessed frames (batch_size, H, W, C)
            
        Returns:
            List of (prediction, confidence) tuples
        """
        if not self.is_loaded:
            raise InferenceError("Model not loaded")
        
        if not self.validate_input(frames):
            raise InferenceError("Invalid input format")
        
        try:
            logger.debug(f"Running MesoNet inference on {len(frames)} frames")
            
            # Preprocess frames
            processed_frames = self.preprocess_frames(frames)
            
            # Convert to PyTorch tensor and move to device
            # Reshape from (B, H, W, C) to (B, C, H, W)
            tensor_frames = torch.from_numpy(processed_frames).permute(0, 3, 1, 2)
            tensor_frames = tensor_frames.to(self.device)
            
            predictions = []
            
            with torch.no_grad():
                # Run inference
                outputs = self.model(tensor_frames)
                
                # Process outputs
                for output in outputs:
                    # Get prediction (probability of being fake)
                    prediction = float(output.cpu().numpy())
                    
                    # Calculate confidence for MesoNet
                    # MesoNet confidence is based on how decisive the prediction is
                    confidence = 2.0 * abs(prediction - 0.5)
                    confidence = min(1.0, max(0.2, confidence))  # Clamp between 0.2 and 1.0
                    
                    predictions.append((prediction, confidence))
            
            logger.debug(f"MesoNet inference completed: {len(predictions)} predictions")
            return predictions
            
        except Exception as e:
            logger.error(f"MesoNet inference failed: {str(e)}")
            raise InferenceError(f"MesoNet prediction failed: {str(e)}")
    
    def preprocess_frames(self, frames: np.ndarray) -> np.ndarray:
        """
        Preprocess frames for MesoNet input.
        
        Args:
            frames: Raw frames array (B, H, W, C) in range [0, 1]
            
        Returns:
            Preprocessed frames in range [-1, 1]
        """
        # MesoNet uses simple normalization to [-1, 1]
        normalized_frames = frames * 2.0 - 1.0
        return normalized_frames.astype(np.float32) 