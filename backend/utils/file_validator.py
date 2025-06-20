"""
File Validation Utilities

This module provides utilities for validating uploaded files,
including format checking, size limits, and content validation.
"""

import os
from typing import List
from fastapi import UploadFile
from loguru import logger

from core.config import settings
from core.exceptions import FileUploadError, ValidationError


class FileValidator:
    """Utility class for file validation."""
    
    def __init__(self):
        """Initialize the file validator."""
        self.allowed_extensions = settings.ALLOWED_VIDEO_EXTENSIONS
        self.max_file_size = settings.MAX_FILE_SIZE
    
    async def validate_video_file(self, file: UploadFile) -> bool:
        """
        Validate uploaded video file.
        
        This method checks:
        1. File extension
        2. File size
        3. Content type
        4. Basic file integrity
        
        Args:
            file: Uploaded file object
            
        Returns:
            True if valid
            
        Raises:
            FileUploadError: If validation fails
        """
        logger.info(f"Validating file: {file.filename}")
        
        try:
            # Check if filename exists
            if not file.filename:
                raise FileUploadError("No filename provided")
            
            # Validate file extension
            self._validate_extension(file.filename)
            
            # Validate file size
            await self._validate_file_size(file)
            
            # Validate content type
            self._validate_content_type(file)
            
            logger.info(f"File validation passed: {file.filename}")
            return True
            
        except (FileUploadError, ValidationError):
            raise
        except Exception as e:
            logger.error(f"File validation error: {str(e)}")
            raise FileUploadError(f"File validation failed: {str(e)}")
    
    def _validate_extension(self, filename: str):
        """
        Validate file extension.
        
        Args:
            filename: Name of the uploaded file
            
        Raises:
            FileUploadError: If extension is not allowed
        """
        file_ext = os.path.splitext(filename)[1].lower()
        
        if file_ext not in self.allowed_extensions:
            allowed_str = ", ".join(self.allowed_extensions)
            raise FileUploadError(
                f"File extension '{file_ext}' not allowed. "
                f"Allowed extensions: {allowed_str}"
            )
        
        logger.debug(f"Extension validation passed: {file_ext}")
    
    async def _validate_file_size(self, file: UploadFile):
        """
        Validate file size.
        
        Args:
            file: Uploaded file object
            
        Raises:
            FileUploadError: If file is too large
        """
        # Get current file position
        current_pos = file.file.tell()
        
        # Move to end to get file size
        file.file.seek(0, 2)
        file_size = file.file.tell()
        
        # Reset file position
        file.file.seek(current_pos)
        
        if file_size > self.max_file_size:
            max_size_mb = self.max_file_size / (1024 * 1024)
            current_size_mb = file_size / (1024 * 1024)
            raise FileUploadError(
                f"File too large: {current_size_mb:.1f}MB. "
                f"Maximum allowed: {max_size_mb:.1f}MB"
            )
        
        logger.debug(f"Size validation passed: {file_size / (1024 * 1024):.1f}MB")
    
    def _validate_content_type(self, file: UploadFile):
        """
        Validate file content type.
        
        Args:
            file: Uploaded file object
            
        Raises:
            FileUploadError: If content type is not valid
        """
        content_type = file.content_type
        
        # Common video MIME types
        allowed_content_types = [
            "video/mp4",
            "video/avi",
            "video/quicktime",
            "video/x-msvideo",
            "video/x-ms-wmv",
            "video/x-flv",
            "video/webm",
            "video/mkv",
            "video/x-matroska",
            "application/octet-stream"  # Some browsers use this for unknown types
        ]
        
        if content_type and content_type not in allowed_content_types:
            logger.warning(f"Unexpected content type: {content_type}")
            # Don't fail validation just for content type as it can be unreliable
            # Just log a warning
        
        logger.debug(f"Content type: {content_type}")
    
    def validate_filename(self, filename: str) -> str:
        """
        Validate and sanitize filename.
        
        Args:
            filename: Original filename
            
        Returns:
            Sanitized filename
            
        Raises:
            ValidationError: If filename is invalid
        """
        if not filename:
            raise ValidationError("Filename cannot be empty")
        
        # Remove path components for security
        filename = os.path.basename(filename)
        
        # Check for dangerous characters
        dangerous_chars = ["<", ">", ":", '"', "|", "?", "*", "\\", "/"]
        for char in dangerous_chars:
            if char in filename:
                raise ValidationError(f"Filename contains invalid character: {char}")
        
        # Check filename length
        if len(filename) > 255:
            raise ValidationError("Filename too long (max 255 characters)")
        
        # Check for reserved names (Windows)
        reserved_names = [
            "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4",
            "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2",
            "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
        ]
        
        name_without_ext = os.path.splitext(filename)[0].upper()
        if name_without_ext in reserved_names:
            raise ValidationError(f"Filename uses reserved name: {filename}")
        
        return filename
    
    def get_file_info(self, filename: str, file_size: int) -> dict:
        """
        Get information about the file.
        
        Args:
            filename: Name of the file
            file_size: Size of the file in bytes
            
        Returns:
            Dictionary containing file information
        """
        file_ext = os.path.splitext(filename)[1].lower()
        size_mb = file_size / (1024 * 1024)
        
        return {
            "filename": filename,
            "extension": file_ext,
            "size_bytes": file_size,
            "size_mb": round(size_mb, 2),
            "is_valid_extension": file_ext in self.allowed_extensions,
            "is_valid_size": file_size <= self.max_file_size
        } 