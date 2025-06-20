"""
Deepfake Detection Service

This module handles the ML model inference for deepfake detection.
It supports multiple models and provides result aggregation across frames.
"""

import numpy as np
import torch
from typing import List, Dict, Any, Tuple, Optional
from loguru import logger
import asyncio
from concurrent.futures import ThreadPoolExecutor
import os

# Try to import TensorFlow, use a fallback if not available
try:
    import tensorflow as tf
    TENSORFLOW_AVAILABLE = True
    logger.info("TensorFlow available")
except ImportError:
    tf = None
    TENSORFLOW_AVAILABLE = False
    logger.warning("TensorFlow not available, using PyTorch only")

from core.config import settings, get_model_config, get_model_path
from core.exceptions import ModelError, InferenceError
from models.base_detector import BaseDetector
from models.xception_detector import XceptionDetector
from models.mesonet_detector import MesoNetDetector

class DetectionService:
    """Service for deepfake detection using ML models."""
    
    def __init__(self):
        """Initialize the detection service."""
        self.models: Dict[str, BaseDetector] = {}
        self.executor = ThreadPoolExecutor(max_workers=2)
        self._model_initialized = False
    
    async def initialize_models(self):
        """Initialize and load all available models."""
        if self._model_initialized:
            return
        
        logger.info("Initializing detection models...")
        
        try:
            # Initialize each configured model
            for model_name in settings.AVAILABLE_MODELS.keys():
                try:
                    await self._load_model(model_name)
                except Exception as e:
                    logger.warning(f"Failed to load model {model_name}: {str(e)}")
            
            self._model_initialized = True
            logger.info(f"Initialized {len(self.models)} models")
            
        except Exception as e:
            logger.error(f"Model initialization failed: {str(e)}")
            raise ModelError(f"Failed to initialize models: {str(e)}")
    
    async def _load_model(self, model_name: str):
        """
        Load a specific model.
        
        Args:
            model_name: Name of the model to load
        """
        try:
            model_config = get_model_config(model_name)
            model_path = get_model_path(model_name)
            
            # Create detector instance based on model type
            if model_name == "xception":
                detector = XceptionDetector(model_path, model_config)
            elif model_name == "mesonet":
                detector = MesoNetDetector(model_path, model_config)
            else:
                logger.warning(f"Unknown model type: {model_name}")
                return
            
            # Load the model
            await detector.load_model()
            self.models[model_name] = detector
            
            logger.info(f"Loaded model: {model_name}")
            
        except Exception as e:
            logger.error(f"❌ Failed to load model {model_name}: {str(e)}")
            raise ModelError(f"Failed to load model {model_name}: {str(e)}")
    
    async def detect_deepfake(
        self,
        frames_data: Dict[str, Any],
        model_name: str = None
    ) -> Dict[str, Any]:
        """
        Run deepfake detection on extracted frames.
        
        Args:
            frames_data: Dictionary containing frames and metadata
            model_name: Model to use for detection (defaults to configured default)
            
        Returns:
            Detection results for all frames
            
        Raises:
            InferenceError: If detection fails
        """
        if not self._model_initialized:
            await self.initialize_models()
        
        model_name = model_name or settings.DEFAULT_MODEL
        
        logger.info(f"Running detection with model: {model_name}")
        
        try:
            frames = frames_data["frames"]
            timestamps = frames_data["timestamps"]
            metadata = frames_data["metadata"]
            
            if not frames:
                raise InferenceError("No frames to analyze")
            
            # For now, create mock predictions to test the flow
            # This will be replaced with actual model inference once models are properly set up
            predictions = []
            for i in range(len(frames)):
                # Mock prediction: random-ish but deterministic based on frame index
                fake_prob = 0.3 + (i % 3) * 0.2  # Varies between 0.3 and 0.7
                confidence = 0.8 + (i % 2) * 0.1  # Varies between 0.8 and 0.9
                predictions.append((fake_prob, confidence))
            
            logger.info(f"Generated {len(predictions)} mock predictions for testing")
            
            # Combine predictions with timestamps
            frame_results = []
            for i, (prediction, timestamp) in enumerate(zip(predictions, timestamps)):
                frame_results.append({
                    "frame_index": i,
                    "timestamp": timestamp,
                    "prediction": float(prediction[0]),  # Probability of being fake
                    "confidence": float(prediction[1]),   # Model confidence
                    "label": "fake" if prediction[0] > settings.MODEL_CONFIDENCE_THRESHOLD else "real"
                })
            
            return {
                "model_used": model_name,
                "total_frames": len(frames),
                "frame_results": frame_results,
                "video_metadata": metadata,
                "detection_metadata": {
                    "model_confidence_threshold": settings.MODEL_CONFIDENCE_THRESHOLD,
                    "batch_size": settings.BATCH_SIZE
                }
            }
            
        except Exception as e:
            logger.error(f"Detection failed: {str(e)}")
            raise InferenceError(f"Detection failed: {str(e)}")
    
    def _run_inference_sync(
        self,
        detector: BaseDetector,
        frames: List[np.ndarray]
    ) -> List[Tuple[float, float]]:
        """
        Run synchronous inference on frames.
        
        Args:
            detector: Model detector instance
            frames: List of preprocessed frames
            
        Returns:
            List of (prediction, confidence) tuples
        """
        predictions = []
        batch_size = settings.BATCH_SIZE
        
        # Process frames in batches for efficiency
        for i in range(0, len(frames), batch_size):
            batch = frames[i:i + batch_size]
            batch_array = np.array(batch)
            
            # Run prediction
            batch_predictions = detector.predict(batch_array)
            predictions.extend(batch_predictions)
            
            logger.info(f"Processed batch {i//batch_size + 1}/{(len(frames) + batch_size - 1)//batch_size}")
        
        return predictions
    
    async def aggregate_results(self, detection_results: Dict[str, Any]) -> Dict[str, Any]:
        """
        Aggregate frame-level results into final video-level prediction.
        
        This method analyzes all frame predictions and provides:
        1. Overall video classification (Real/Fake)
        2. Confidence score
        3. Suspicious frame analysis
        4. Statistical summary
        
        Args:
            detection_results: Results from detect_deepfake method
            
        Returns:
            Aggregated results with final prediction
        """
        logger.info("Aggregating detection results...")
        
        try:
            frame_results = detection_results["frame_results"]
            
            if not frame_results:
                raise InferenceError("No frame results to aggregate")
            
            # Extract predictions and confidences
            predictions = [result["prediction"] for result in frame_results]
            confidences = [result["confidence"] for result in frame_results]
            
            # Calculate statistics
            mean_prediction = np.mean(predictions)
            std_prediction = np.std(predictions)
            mean_confidence = np.mean(confidences)
            
            # Count fake/real frames
            fake_frames = [r for r in frame_results if r["label"] == "fake"]
            real_frames = [r for r in frame_results if r["label"] == "real"]
            
            fake_percentage = len(fake_frames) / len(frame_results) * 100
            
            # Determine final classification
            # Use a simple majority vote with confidence weighting
            weighted_prediction = np.average(predictions, weights=confidences)
            
            final_label = "fake" if weighted_prediction > settings.MODEL_CONFIDENCE_THRESHOLD else "real"
            final_confidence = mean_confidence  # Keep as decimal (0-1) for frontend
            
            # Identify most suspicious frames (highest fake prediction)
            suspicious_frames = sorted(
                frame_results,
                key=lambda x: x["prediction"],
                reverse=True
            )[:5]  # Top 5 most suspicious frames
            
            # Create summary
            summary = {
                "prediction": final_label,
                "confidence": round(final_confidence, 4),  # Keep as decimal
                "fake_probability": round(weighted_prediction * 100, 2),
                "statistics": {
                    "total_frames": len(frame_results),
                    "fake_frames": len(fake_frames),
                    "real_frames": len(real_frames),
                    "fake_percentage": round(fake_percentage, 2),
                    "mean_prediction": round(mean_prediction, 4),
                    "std_prediction": round(std_prediction, 4),
                    "mean_confidence": round(mean_confidence, 4)
                },
                "suspicious_frames": [
                    {
                        "timestamp": frame["timestamp"],
                        "frame_index": frame["frame_index"],
                        "fake_probability": round(frame["prediction"] * 100, 2),
                        "confidence": round(frame["confidence"] * 100, 2)
                    }
                    for frame in suspicious_frames
                ],
                "model_info": {
                    "model_used": detection_results["model_used"],
                    "threshold": settings.MODEL_CONFIDENCE_THRESHOLD,
                    "total_frames_analyzed": detection_results["total_frames"]
                }
            }
            
            logger.info(f"Aggregation complete: {final_label} ({final_confidence * 100:.1f}% confidence)")
            
            return summary
            
        except Exception as e:
            logger.error(f"Result aggregation failed: {str(e)}")
            raise InferenceError(f"Result aggregation failed: {str(e)}")
    
    async def get_available_models(self) -> List[Dict[str, Any]]:
        """
        Get list of available models with their status.
        
        Returns:
            List of model information dictionaries
        """
        models_info = []
        
        for model_name, config in settings.AVAILABLE_MODELS.items():
            is_loaded = model_name in self.models
            model_path = get_model_path(model_name)
            is_available = os.path.exists(model_path)
            
            models_info.append({
                "name": model_name,
                "display_name": config["name"],
                "description": config["description"],
                "is_loaded": is_loaded,
                "is_available": is_available,
                "input_size": config["input_size"],
                "preprocessing": config["preprocessing"]
            })
        
        return models_info
    
    def __del__(self):
        """Cleanup when service is destroyed."""
        if hasattr(self, 'executor'):
            self.executor.shutdown(wait=True)
    
    async def analyze_video(self, video_path: str, model_name: str = None) -> Dict[str, Any]:
        """
        Analyze video for deepfake detection (simplified version for testing).
        
        Args:
            video_path: Path to the video file
            model_name: Model to use for detection
            
        Returns:
            Dictionary with detection results
        """
        # For now, extract frames and run detection
        from services.video_processor import VideoProcessor
        
        video_processor = VideoProcessor()
        frames_data = await video_processor.extract_frames(video_path)
        
        # Run detection on frames
        detection_results = await self.detect_deepfake(frames_data, model_name)
        
        # Aggregate results
        aggregated_results = await self.aggregate_results(detection_results)
        
        return {
            **detection_results,
            "aggregated_results": aggregated_results,
            "processing_time": 2.5  # Mock processing time
        } 