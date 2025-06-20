"""
Video Processing Service

This module handles video file processing, including frame extraction,
validation, and preprocessing for deepfake detection models.
Uses OpenCV for efficient video processing operations.
"""

import cv2
import os
import numpy as np
from typing import List, Dict, Any, Tuple, Optional
from loguru import logger
import asyncio
from concurrent.futures import ThreadPoolExecutor

from core.config import settings
from core.exceptions import VideoProcessingError


class VideoProcessor:
    """Service class for video processing operations."""
    
    def __init__(self):
        """Initialize the video processor."""
        self.executor = ThreadPoolExecutor(max_workers=4)
    
    async def extract_frames(self, video_path: str) -> Dict[str, Any]:
        """
        Extract frames from video file for analysis.
        
        This method:
        1. Opens the video file using OpenCV
        2. Extracts frames at specified intervals
        3. Preprocesses frames for model input
        4. Returns frame data with metadata
        
        Args:
            video_path: Path to the video file
            
        Returns:
            Dictionary containing frames and metadata
            
        Raises:
            VideoProcessingError: If video processing fails
        """
        logger.info(f"Starting frame extraction from: {video_path}")
        
        try:
            # Run frame extraction in thread pool to avoid blocking
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                self.executor,
                self._extract_frames_sync,
                video_path
            )
            
            logger.info(f"Frame extraction completed: {len(result['frames'])} frames extracted")
            return result
            
        except Exception as e:
            logger.error(f"Frame extraction failed: {str(e)}")
            raise VideoProcessingError(f"Failed to extract frames: {str(e)}")
    
    def _extract_frames_sync(self, video_path: str) -> Dict[str, Any]:
        """
        Synchronous frame extraction implementation.
        
        Args:
            video_path: Path to the video file
            
        Returns:
            Dictionary containing extracted frames and metadata
        """
        if not os.path.exists(video_path):
            raise VideoProcessingError(f"Video file not found: {video_path}")
        
        # Open video file
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise VideoProcessingError(f"Could not open video file: {video_path}")
        
        try:
            # Get video properties
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = frame_count / fps if fps > 0 else 0
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            
            logger.info(f"Video properties: {width}x{height}, {fps:.2f} FPS, {duration:.2f}s")
            
            # Calculate frame extraction interval
            # Extract one frame per second by default
            frame_interval = max(1, int(fps / settings.FRAME_EXTRACTION_RATE))
            
            frames = []
            frame_timestamps = []
            frame_number = 0
            extracted_count = 0
            
            while True:
                ret, frame = cap.read()
                
                if not ret:
                    break
                
                # Extract frame at specified intervals
                if frame_number % frame_interval == 0:
                    # Stop if we've reached the maximum frame limit
                    if extracted_count >= settings.MAX_FRAMES_PER_VIDEO:
                        logger.info(f"Reached maximum frame limit: {settings.MAX_FRAMES_PER_VIDEO}")
                        break
                    
                    # Preprocess frame
                    processed_frame = self._preprocess_frame(frame)
                    
                    frames.append(processed_frame)
                    frame_timestamps.append(frame_number / fps)
                    extracted_count += 1
                    
                    if extracted_count % 10 == 0:
                        logger.info(f"Extracted {extracted_count} frames...")
                
                frame_number += 1
            
            return {
                "frames": frames,
                "timestamps": frame_timestamps,
                "metadata": {
                    "original_fps": fps,
                    "total_frames": frame_count,
                    "duration": duration,
                    "resolution": (width, height),
                    "extracted_frames": len(frames),
                    "extraction_rate": settings.FRAME_EXTRACTION_RATE,
                    "frame_interval": frame_interval
                }
            }
            
        finally:
            cap.release()
    
    def _preprocess_frame(self, frame: np.ndarray) -> np.ndarray:
        """
        Preprocess frame for model input.
        
        This method:
        1. Resizes frame to model input size
        2. Converts color space if needed
        3. Normalizes pixel values
        
        Args:
            frame: Raw frame from video
            
        Returns:
            Preprocessed frame ready for model input
        """
        # Resize to standard input size for models
        target_size = settings.VIDEO_RESOLUTION
        resized_frame = cv2.resize(frame, target_size)
        
        # Convert BGR to RGB (OpenCV uses BGR by default)
        rgb_frame = cv2.cvtColor(resized_frame, cv2.COLOR_BGR2RGB)
        
        # Normalize pixel values to [0, 1]
        normalized_frame = rgb_frame.astype(np.float32) / 255.0
        
        return normalized_frame
    
    async def get_video_info(self, video_path: str) -> Dict[str, Any]:
        """
        Get basic information about a video file.
        
        Args:
            video_path: Path to the video file
            
        Returns:
            Dictionary containing video information
            
        Raises:
            VideoProcessingError: If video analysis fails
        """
        try:
            loop = asyncio.get_event_loop()
            info = await loop.run_in_executor(
                self.executor,
                self._get_video_info_sync,
                video_path
            )
            return info
            
        except Exception as e:
            logger.error(f"Failed to get video info: {str(e)}")
            raise VideoProcessingError(f"Failed to analyze video: {str(e)}")
    
    def _get_video_info_sync(self, video_path: str) -> Dict[str, Any]:
        """
        Synchronous video information extraction.
        
        Args:
            video_path: Path to the video file
            
        Returns:
            Dictionary containing video metadata
        """
        if not os.path.exists(video_path):
            raise VideoProcessingError(f"Video file not found: {video_path}")
        
        cap = cv2.VideoCapture(video_path)
        
        if not cap.isOpened():
            raise VideoProcessingError(f"Could not open video file: {video_path}")
        
        try:
            fps = cap.get(cv2.CAP_PROP_FPS)
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            duration = frame_count / fps if fps > 0 else 0
            width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
            height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            
            # Get file size
            file_size = os.path.getsize(video_path)
            
            return {
                "fps": fps,
                "frame_count": frame_count,
                "duration": duration,
                "resolution": {
                    "width": width,
                    "height": height
                },
                "file_size": file_size,
                "format": os.path.splitext(video_path)[1].lower()
            }
            
        finally:
            cap.release()
    
    async def validate_video_file(self, video_path: str) -> bool:
        """
        Validate if the file is a valid video.
        
        Args:
            video_path: Path to the video file
            
        Returns:
            True if valid, False otherwise
            
        Raises:
            VideoProcessingError: If validation fails
        """
        try:
            # Check if file exists
            if not os.path.exists(video_path):
                return False
            
            # Check file extension
            file_ext = os.path.splitext(video_path)[1].lower()
            if file_ext not in settings.ALLOWED_VIDEO_EXTENSIONS:
                return False
            
            # Try to open with OpenCV
            cap = cv2.VideoCapture(video_path)
            is_valid = cap.isOpened()
            
            if is_valid:
                # Check if we can read at least one frame
                ret, _ = cap.read()
                is_valid = ret
            
            cap.release()
            return is_valid
            
        except Exception as e:
            logger.error(f"❌ Video validation failed: {str(e)}")
            raise VideoProcessingError(f"Video validation failed: {str(e)}")
    
    def __del__(self):
        """Cleanup when processor is destroyed."""
        if hasattr(self, 'executor'):
            self.executor.shutdown(wait=True) 