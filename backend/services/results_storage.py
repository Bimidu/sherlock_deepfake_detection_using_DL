"""
Results Storage Service

This module handles saving and loading analysis results to/from text files.
Results are stored in a structured directory for easy access and persistence.
"""

import os
import json
from datetime import datetime
from typing import Dict, Any, List, Optional
from pathlib import Path
from loguru import logger

from core.config import settings


class ResultsStorage:
    """Service for managing persistent storage of analysis results."""
    
    def __init__(self):
        """Initialize the results storage service."""
        self.storage_dir = Path(settings.BASE_DIR) / "stored_results"
        self.storage_dir.mkdir(exist_ok=True)
        logger.info(f"Results storage initialized: {self.storage_dir}")
    
    def save_result(self, task_id: str, result_data: Dict[str, Any]) -> str:
        """
        Save analysis result to a text file.
        
        Args:
            task_id: Unique task identifier
            result_data: Complete result data to save
            
        Returns:
            Path to the saved file
        """
        try:
            # Create filename with timestamp for easy sorting
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{timestamp}_{task_id}.json"
            file_path = self.storage_dir / filename
            
            # Prepare data for storage
            storage_data = {
                "task_id": task_id,
                "timestamp": datetime.now().isoformat(),
                "filename": result_data.get("video_info", {}).get("filename", "unknown"),
                "model_used": result_data.get("model_used", "unknown"),
                "results": result_data
            }
            
            # Save to file
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(storage_data, f, indent=2, ensure_ascii=False)
            
            logger.info(f"Saved result to file: {filename}")
            return str(file_path)
            
        except Exception as e:
            logger.error(f"Failed to save result for task {task_id}: {str(e)}")
            raise
    
    def load_result(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Load analysis result from file by task ID.
        
        Args:
            task_id: Task identifier to search for
            
        Returns:
            Loaded result data or None if not found
        """
        try:
            # Search for file containing this task ID
            for file_path in self.storage_dir.glob("*_*.json"):
                if task_id in file_path.name:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        if data.get("task_id") == task_id:
                            return data
            
            logger.warning(f"No stored result found for task: {task_id}")
            return None
            
        except Exception as e:
            logger.error(f"Failed to load result for task {task_id}: {str(e)}")
            return None
    
    def list_results(self, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
        """
        List stored results with pagination.
        
        Args:
            limit: Maximum number of results to return
            offset: Number of results to skip
            
        Returns:
            List of result summaries
        """
        try:
            results = []
            
            # Get all result files sorted by modification time (newest first)
            result_files = sorted(
                self.storage_dir.glob("*.json"),
                key=lambda x: x.stat().st_mtime,
                reverse=True
            )
            
            # Apply pagination
            paginated_files = result_files[offset:offset + limit]
            
            for file_path in paginated_files:
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        
                        # Extract summary information
                        result_summary = {
                            "task_id": data.get("task_id"),
                            "timestamp": data.get("timestamp"),
                            "filename": data.get("filename"),
                            "model_used": data.get("model_used"),
                            "file_path": str(file_path)
                        }
                        
                        # Add result summary if available
                        results_data = data.get("results", {})
                        if results_data:
                            result_summary.update({
                                "prediction": results_data.get("prediction"),
                                "confidence": results_data.get("confidence"),
                                "fake_probability": results_data.get("fake_probability"),
                                "total_frames": results_data.get("total_frames", 0)
                            })
                        
                        results.append(result_summary)
                        
                except Exception as e:
                    logger.warning(f"Failed to read result file {file_path}: {str(e)}")
                    continue
            
            logger.info(f"Listed {len(results)} stored results")
            return results
            
        except Exception as e:
            logger.error(f"Failed to list stored results: {str(e)}")
            return []
    
    def delete_result(self, task_id: str) -> bool:
        """
        Delete a stored result by task ID.
        
        Args:
            task_id: Task identifier
            
        Returns:
            True if deleted, False if not found
        """
        try:
            # Find and delete the file
            for file_path in self.storage_dir.glob("*_*.json"):
                if task_id in file_path.name:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)
                        if data.get("task_id") == task_id:
                            file_path.unlink()
                            logger.info(f"Deleted stored result: {task_id}")
                            return True
            
            logger.warning(f"No stored result found to delete: {task_id}")
            return False
            
        except Exception as e:
            logger.error(f"Failed to delete result {task_id}: {str(e)}")
            return False
    
    def get_storage_stats(self) -> Dict[str, Any]:
        """
        Get storage statistics.
        
        Returns:
            Dictionary with storage statistics
        """
        try:
            result_files = list(self.storage_dir.glob("*.json"))
            total_files = len(result_files)
            
            # Calculate total storage size
            total_size = sum(f.stat().st_size for f in result_files)
            total_size_mb = total_size / (1024 * 1024)
            
            return {
                "total_results": total_files,
                "storage_size_mb": round(total_size_mb, 2),
                "storage_directory": str(self.storage_dir)
            }
            
        except Exception as e:
            logger.error(f"Failed to get storage stats: {str(e)}")
            return {
                "total_results": 0,
                "storage_size_mb": 0,
                "storage_directory": str(self.storage_dir)
            }


# Global instance
results_storage = ResultsStorage() 