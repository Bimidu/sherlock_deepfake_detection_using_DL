"""
XceptionNet Deepfake Detector

Implementation of deepfake detection using XceptionNet architecture.
XceptionNet is known for high accuracy in deepfake detection tasks.
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


class XceptionDetector(BaseDetector):
    """XceptionNet-based deepfake detector."""
    
    def __init__(self, model_path: str, config: Dict[str, Any]):
        """Initialize XceptionNet detector."""
        super().__init__(model_path, config)
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.transform = None
        
    async def load_model(self):
        """Load XceptionNet model."""
        try:
            logger.info(f"🔄 Loading XceptionNet model from: {self.model_path}")
            
            # Check if model file exists
            if not os.path.exists(self.model_path):
                # For demo purposes, create a simple CNN model
                # In production, you would load a pre-trained XceptionNet
                logger.warning("⚠️ Model file not found, creating demo model")
                self.model = self._create_demo_model()
            else:
                # Load actual pre-trained model
                self.model = torch.load(self.model_path, map_location=self.device)
            
            self.model.to(self.device)
            self.model.eval()
            
            # Set up preprocessing transforms
            self._setup_transforms()
            
            self.is_loaded = True
            logger.info("✅ XceptionNet model loaded successfully")
            
        except Exception as e:
            logger.error(f"❌ Failed to load XceptionNet model: {str(e)}")
            raise ModelError(f"Failed to load XceptionNet: {str(e)}")
    
    def _create_demo_model(self) -> nn.Module:
        """
        Create a demo CNN model for testing purposes.
        
        In production, this would be replaced with actual XceptionNet
        architecture and pre-trained weights.
        """
        class DemoXceptionNet(nn.Module):
            def __init__(self):
                super(DemoXceptionNet, self).__init__()
                
                # Simple CNN architecture for demo
                self.features = nn.Sequential(
                    # First conv block
                    nn.Conv2d(3, 32, kernel_size=3, stride=2, padding=1),
                    nn.BatchNorm2d(32),
                    nn.ReLU(inplace=True),
                    
                    # Second conv block
                    nn.Conv2d(32, 64, kernel_size=3, stride=2, padding=1),
                    nn.BatchNorm2d(64),
                    nn.ReLU(inplace=True),
                    
                    # Third conv block
                    nn.Conv2d(64, 128, kernel_size=3, stride=2, padding=1),
                    nn.BatchNorm2d(128),
                    nn.ReLU(inplace=True),
                    
                    # Fourth conv block
                    nn.Conv2d(128, 256, kernel_size=3, stride=2, padding=1),
                    nn.BatchNorm2d(256),
                    nn.ReLU(inplace=True),
                    
                    # Global average pooling
                    nn.AdaptiveAvgPool2d((1, 1))
                )
                
                # Classifier
                self.classifier = nn.Sequential(
                    nn.Dropout(0.5),
                    nn.Linear(256, 128),
                    nn.ReLU(inplace=True),
                    nn.Dropout(0.3),
                    nn.Linear(128, 1),
                    nn.Sigmoid()
                )
            
            def forward(self, x):
                x = self.features(x)
                x = torch.flatten(x, 1)
                x = self.classifier(x)
                return x
        
        return DemoXceptionNet()
    
    def _setup_transforms(self):
        """Set up image preprocessing transforms."""
        if self.preprocessing == "imagenet":
            # Standard ImageNet preprocessing
            self.transform = transforms.Compose([
                transforms.TensorType(torch.FloatTensor),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],
                    std=[0.229, 0.224, 0.225]
                )
            ])
        else:
            # Simple normalization
            self.transform = transforms.Compose([
                transforms.TensorType(torch.FloatTensor),
                transforms.Normalize(mean=[0.5, 0.5, 0.5], std=[0.5, 0.5, 0.5])
            ])
    
    def predict(self, frames: np.ndarray) -> List[Tuple[float, float]]:
        """
        Run prediction on frames using XceptionNet.
        
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
            logger.debug(f"🔍 Running XceptionNet inference on {len(frames)} frames")
            
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
                    
                    # Calculate confidence based on distance from 0.5
                    # Higher confidence when prediction is closer to 0 or 1
                    confidence = 1.0 - 2.0 * abs(prediction - 0.5)
                    confidence = max(0.1, confidence)  # Minimum confidence of 0.1
                    
                    predictions.append((prediction, confidence))
            
            logger.debug(f"✅ XceptionNet inference completed: {len(predictions)} predictions")
            return predictions
            
        except Exception as e:
            logger.error(f"❌ XceptionNet inference failed: {str(e)}")
            raise InferenceError(f"XceptionNet prediction failed: {str(e)}")
    
    def preprocess_frames(self, frames: np.ndarray) -> np.ndarray:
        """
        Preprocess frames for XceptionNet input.
        
        Args:
            frames: Raw frames array (B, H, W, C) in range [0, 1]
            
        Returns:
            Preprocessed frames
        """
        if self.preprocessing == "imagenet":
            # Apply ImageNet normalization
            # Note: This is a simplified version
            # In practice, you'd use torchvision.transforms
            mean = np.array([0.485, 0.456, 0.406])
            std = np.array([0.229, 0.224, 0.225])
            
            normalized_frames = (frames - mean) / std
            
        else:
            # Simple normalization to [-1, 1]
            normalized_frames = frames * 2.0 - 1.0
        
        return normalized_frames.astype(np.float32) 