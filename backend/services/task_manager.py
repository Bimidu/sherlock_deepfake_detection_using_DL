"""
Task Manager Service

This module manages video processing tasks, including creation, status updates,
result storage, and cleanup. Uses in-memory storage for simplicity
(can be extended to use a database in production).
"""

import uuid
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from loguru import logger
import asyncio
import json

from core.exceptions import TaskNotFoundError


class TaskManager:
    """Service for managing video processing tasks."""
    
    def __init__(self):
        """Initialize the task manager."""
        self.tasks: Dict[str, Dict[str, Any]] = {}
        self.lock = asyncio.Lock()
    
    async def create_task(self, task_id: str, task_data: Dict[str, Any]) -> str:
        """
        Create a new processing task.
        
        Args:
            task_id: Unique task identifier
            task_data: Initial task data
            
        Returns:
            Created task ID
        """
        async with self.lock:
            self.tasks[task_id] = {
                **task_data,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat(),
                "status": "created",
                "progress": 0
            }
        
        logger.info(f"Created task: {task_id}")
        return task_id
    
    async def get_task(self, task_id: str) -> Optional[Dict[str, Any]]:
        """
        Get task data by ID.
        
        Args:
            task_id: Unique task identifier
            
        Returns:
            Task data or None if not found
        """
        async with self.lock:
            return self.tasks.get(task_id)
    
    async def update_task_status(
        self,
        task_id: str,
        status: str,
        progress: Optional[int] = None,
        additional_data: Optional[Dict[str, Any]] = None
    ):
        """
        Update task status and progress.
        
        Args:
            task_id: Unique task identifier
            status: New task status
            progress: Progress percentage (0-100)
            additional_data: Additional data to merge
        """
        async with self.lock:
            if task_id not in self.tasks:
                raise TaskNotFoundError(task_id)
            
            self.tasks[task_id]["status"] = status
            self.tasks[task_id]["updated_at"] = datetime.utcnow().isoformat()
            
            if progress is not None:
                self.tasks[task_id]["progress"] = progress
            
            if additional_data:
                self.tasks[task_id].update(additional_data)
        
        logger.info(f"Updated task {task_id}: {status} ({progress}%)")
    
    async def complete_task(self, task_id: str, results: Dict[str, Any]):
        """
        Mark task as completed with results.
        
        Args:
            task_id: Unique task identifier
            results: Detection results
        """
        await self.update_task_status(
            task_id,
            "completed",
            progress=100,
            additional_data={
                "results": results,
                "completed_at": datetime.utcnow().isoformat()
            }
        )
        
        logger.info(f"Completed task: {task_id}")
    
    async def fail_task(self, task_id: str, error: str):
        """
        Mark task as failed with error message.
        
        Args:
            task_id: Unique task identifier
            error: Error message
        """
        await self.update_task_status(
            task_id,
            "failed",
            additional_data={
                "error": error,
                "failed_at": datetime.utcnow().isoformat()
            }
        )
        
        logger.error(f"Failed task {task_id}: {error}")
    
    async def delete_task(self, task_id: str):
        """
        Delete a task.
        
        Args:
            task_id: Unique task identifier
        """
        async with self.lock:
            if task_id not in self.tasks:
                raise TaskNotFoundError(task_id)
            
            del self.tasks[task_id]
        
        logger.info(f"Deleted task: {task_id}")
    
    async def list_tasks(
        self,
        limit: int = 10,
        offset: int = 0,
        status_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        List tasks with pagination and filtering.
        
        Args:
            limit: Maximum number of tasks to return
            offset: Number of tasks to skip
            status_filter: Optional status filter
            
        Returns:
            List of tasks
        """
        async with self.lock:
            tasks_list = list(self.tasks.values())
            
            # Filter by status if specified
            if status_filter:
                tasks_list = [t for t in tasks_list if t.get("status") == status_filter]
            
            # Sort by creation time (newest first)
            tasks_list.sort(
                key=lambda x: x.get("created_at", ""),
                reverse=True
            )
            
            # Apply pagination
            paginated_tasks = tasks_list[offset:offset + limit]
            
            # Remove sensitive data from response
            public_tasks = []
            for task in paginated_tasks:
                public_task = {
                    "task_id": task.get("task_id"),
                    "filename": task.get("filename"),
                    "status": task.get("status"),
                    "progress": task.get("progress", 0),
                    "created_at": task.get("created_at"),
                    "completed_at": task.get("completed_at"),
                    "model_name": task.get("model_name")
                }
                
                # Include results summary if completed
                if task.get("status") == "completed" and "results" in task:
                    results = task["results"]
                    public_task["results_summary"] = {
                        "prediction": results.get("prediction"),
                        "confidence": results.get("confidence"),
                        "fake_probability": results.get("fake_probability")
                    }
                
                public_tasks.append(public_task)
            
            return public_tasks
    
    async def get_active_task_count(self) -> int:
        """
        Get count of active (processing) tasks.
        
        Returns:
            Number of active tasks
        """
        async with self.lock:
            active_statuses = ["created", "uploaded", "processing"]
            active_count = sum(
                1 for task in self.tasks.values()
                if task.get("status") in active_statuses
            )
            return active_count
    
    async def get_total_task_count(self) -> int:
        """
        Get total number of tasks.
        
        Returns:
            Total task count
        """
        async with self.lock:
            return len(self.tasks)
    
    async def cleanup_old_tasks(self, max_age_hours: int = 24):
        """
        Clean up old tasks to prevent memory bloat.
        
        Args:
            max_age_hours: Maximum age of tasks to keep (in hours)
        """
        cutoff_time = datetime.utcnow() - timedelta(hours=max_age_hours)
        cutoff_str = cutoff_time.isoformat()
        
        async with self.lock:
            tasks_to_delete = []
            
            for task_id, task_data in self.tasks.items():
                # Only delete completed or failed tasks
                status = task_data.get("status")
                if status in ["completed", "failed"]:
                    created_at = task_data.get("created_at", "")
                    if created_at < cutoff_str:
                        tasks_to_delete.append(task_id)
            
            # Delete old tasks
            for task_id in tasks_to_delete:
                del self.tasks[task_id]
            
            if tasks_to_delete:
                logger.info(f"🧹 Cleaned up {len(tasks_to_delete)} old tasks")
    
    async def get_task_statistics(self) -> Dict[str, Any]:
        """
        Get task statistics.
        
        Returns:
            Dictionary containing task statistics
        """
        async with self.lock:
            total_tasks = len(self.tasks)
            
            status_counts = {}
            for task in self.tasks.values():
                status = task.get("status", "unknown")
                status_counts[status] = status_counts.get(status, 0) + 1
            
            # Calculate completion rate
            completed = status_counts.get("completed", 0)
            failed = status_counts.get("failed", 0)
            total_finished = completed + failed
            
            completion_rate = (completed / total_finished * 100) if total_finished > 0 else 0
            
            return {
                "total_tasks": total_tasks,
                "status_counts": status_counts,
                "completion_rate": round(completion_rate, 2),
                "active_tasks": status_counts.get("processing", 0) + status_counts.get("uploaded", 0)
            } 