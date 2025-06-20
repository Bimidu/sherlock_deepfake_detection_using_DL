# Sherlock Backend - FastAPI Server

This is the backend component of the Sherlock deepfake detection system. It provides REST API endpoints for video upload, processing, and AI-powered deepfake detection using state-of-the-art machine learning models.

## 🏗️ Architecture

The backend is built with a modular, scalable architecture:

```
backend/
├── api/                    # API routes and endpoints
│   └── routes/            # Route handlers
├── core/                  # Core application logic
│   ├── config.py         # Configuration settings
│   ├── exceptions.py     # Custom exceptions
│   └── model_manager.py  # ML model management
├── models/               # ML model implementations
│   ├── base_detector.py  # Base detector interface
│   ├── xception_detector.py  # XceptionNet implementation
│   └── mesonet_detector.py   # MesoNet implementation
├── services/             # Business logic services
│   ├── video_processor.py    # Video processing service
│   ├── detection_service.py  # Detection inference service
│   └── task_manager.py       # Task management service
├── utils/                # Utility functions
│   └── file_validator.py     # File validation utilities
└── main.py              # Application entry point
```

## 🚀 Features

### Video Processing
- **Frame Extraction**: Extract frames from video files using OpenCV
- **Preprocessing**: Resize, normalize, and prepare frames for ML models
- **Format Support**: Support for MP4, AVI, MOV, MKV, WebM, and more
- **Size Validation**: Configurable file size limits and format checking

### ML Model Support
- **XceptionNet**: High-accuracy deepfake detection model
- **MesoNet**: Lightweight model for real-time processing
- **Modular Design**: Easy to add new models and architectures
- **GPU Support**: Automatic GPU acceleration when available

### API Features
- **Async Processing**: Non-blocking video processing with background tasks
- **Progress Tracking**: Real-time progress updates for video processing
- **Result Aggregation**: Intelligent frame-level result aggregation
- **CORS Support**: Cross-origin requests for Flutter app communication
- **Error Handling**: Comprehensive error handling and logging

### Monitoring & Health
- **Health Checks**: Multiple health check endpoints for monitoring
- **System Metrics**: CPU, memory, and disk usage monitoring
- **Logging**: Structured logging with rotation and retention
- **Task Statistics**: Processing statistics and performance metrics

## 🛠️ Installation

### Prerequisites

- Python 3.8 or higher
- CUDA-capable GPU (optional, for faster inference)
- FFmpeg (for video processing)

### Local Development

1. **Clone and navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. **Run the server**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

### Docker Deployment

1. **Build the Docker image**
   ```bash
   docker build -t sherlock-backend .
   ```

2. **Run the container**
   ```bash
   docker run -p 8000:8000 -v $(pwd)/models:/app/models sherlock-backend
   ```

3. **Using Docker Compose** (recommended)
   ```bash
   docker-compose up -d
   ```

### Production Deployment

For production deployment, consider:

1. **Use a process manager**: Gunicorn with multiple workers
   ```bash
   gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
   ```

2. **Set up reverse proxy**: Use Nginx for SSL termination and load balancing

3. **Configure monitoring**: Set up log aggregation and health monitoring

4. **Environment variables**: Configure production settings via environment variables

## 📊 API Documentation

### Base URL
- Development: `http://localhost:8000`
- Production: `https://your-domain.com`

### Authentication
Currently, the API supports optional API key authentication. Set `API_KEY` in your environment variables to enable.

### Main Endpoints

#### Upload Video for Analysis
```http
POST /api/v1/upload
Content-Type: multipart/form-data

{
  "file": "video_file.mp4",
  "model_name": "xception"  # optional
}
```

**Response:**
```json
{
  "success": true,
  "task_id": "uuid-string",
  "message": "Video uploaded successfully. Processing started.",
  "filename": "video_file.mp4",
  "model": "xception",
  "status_url": "/api/v1/results/uuid-string"
}
```

#### Get Detection Results
```http
GET /api/v1/results/{task_id}
```

**Response:**
```json
{
  "task_id": "uuid-string",
  "status": "completed",
  "progress": 100,
  "results": {
    "prediction": "fake",
    "confidence": 85.2,
    "fake_probability": 87.5,
    "statistics": {
      "total_frames": 120,
      "fake_frames": 105,
      "real_frames": 15,
      "fake_percentage": 87.5
    },
    "suspicious_frames": [
      {
        "timestamp": 2.5,
        "frame_index": 75,
        "fake_probability": 95.2,
        "confidence": 92.1
      }
    ]
  }
}
```

#### List Available Models
```http
GET /api/v1/models
```

#### Health Check
```http
GET /api/v1/health
```

### Interactive Documentation
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## 🧠 Models

### Adding New Models

1. **Create model class** inheriting from `BaseDetector`:
   ```python
   from models.base_detector import BaseDetector

   class MyDetector(BaseDetector):
       async def load_model(self):
           # Implement model loading
           pass

       def predict(self, frames):
           # Implement prediction logic
           pass

       def preprocess_frames(self, frames):
           # Implement preprocessing
           pass
   ```

2. **Register in configuration**:
   ```python
   # core/config.py
   AVAILABLE_MODELS = {
       "my_model": {
           "name": "My Model",
           "description": "Description of my model",
           "file": "my_model.pth",
           "input_size": (224, 224),
           "preprocessing": "custom"
       }
   }
   ```

3. **Update model manager**:
   ```python
   # core/model_manager.py
   def _create_detector(self, model_name, model_path, config):
       if model_name == "my_model":
           return MyDetector(model_path, config)
   ```

### Model Files

Place your model files in the `models/` directory:
```
models/
├── xception_deepfake_detector.pth
├── mesonet_deepfake_detector.pth
└── your_model.pth
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file:

```bash
# Application Settings
ENVIRONMENT=development
DEBUG=true
HOST=0.0.0.0
PORT=8000

# CORS Settings
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
ALLOWED_HOSTS=localhost,127.0.0.1

# File Upload Settings
MAX_FILE_SIZE=104857600  # 100MB
ALLOWED_VIDEO_EXTENSIONS=.mp4,.avi,.mov,.mkv,.flv,.wmv,.webm

# Model Settings
DEFAULT_MODEL=xception
MODEL_CONFIDENCE_THRESHOLD=0.5
BATCH_SIZE=32

# Processing Settings
FRAME_EXTRACTION_RATE=1
MAX_FRAMES_PER_VIDEO=300
MAX_CONCURRENT_TASKS=10

# Security
SECRET_KEY=your-secret-key-here
API_KEY=your-api-key-here  # optional

# Paths
MODELS_DIR=./models
UPLOAD_DIR=./uploads
TEMP_DIR=./temp
LOGS_DIR=./logs
```

### Performance Tuning

#### For CPU-only deployment:
```bash
# Reduce batch size for lower memory usage
BATCH_SIZE=8
MAX_CONCURRENT_TASKS=2
```

#### For GPU deployment:
```bash
# Increase batch size for better GPU utilization
BATCH_SIZE=64
MAX_CONCURRENT_TASKS=5
```

#### For high-throughput scenarios:
```bash
# Increase worker processes
WORKERS=4
MAX_CONCURRENT_TASKS=20
```

## 🔧 Development

### Running Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx

# Run tests
pytest tests/

# Run with coverage
pytest --cov=./ tests/
```

### Code Quality

```bash
# Format code
black .

# Lint code
flake8 .

# Type checking
mypy .
```

### Development Tools

```bash
# Start with auto-reload
uvicorn main:app --reload

# Debug mode
DEBUG=true uvicorn main:app --reload

# Profile performance
py-spy top --pid $(pgrep -f "uvicorn")
```

## 📝 Logging

The application uses structured logging with the `loguru` library:

```python
from loguru import logger

logger.info("Processing video: {filename}", filename="video.mp4")
logger.error("Model inference failed: {error}", error=str(e))
```

Logs are written to:
- Console (with colors in development)
- `logs/sherlock.log` (with rotation)

## 🔒 Security Considerations

### File Upload Security
- File type validation
- File size limits
- Filename sanitization
- Temporary file cleanup

### API Security
- Optional API key authentication
- CORS configuration
- Input validation
- Error message sanitization

### Production Deployment
- Use HTTPS in production
- Configure firewall rules
- Implement rate limiting
- Monitor for suspicious activity

## 🐛 Troubleshooting

### Common Issues

**Model loading errors:**
```bash
# Check if model files exist
ls -la models/

# Check GPU availability
python -c "import torch; print(torch.cuda.is_available())"
```

**Memory issues:**
```bash
# Reduce batch size in config
BATCH_SIZE=4

# Monitor memory usage
htop
```

**CORS errors:**
```bash
# Check CORS configuration
curl -X OPTIONS http://localhost:8000/api/v1/upload \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST"
```

### Debug Mode

Enable debug mode for detailed error information:
```bash
DEBUG=true uvicorn main:app --reload --log-level debug
```

## 📈 Monitoring

### Health Endpoints

- `GET /api/v1/health` - Basic health check
- `GET /api/v1/health/detailed` - Detailed system metrics
- `GET /api/v1/health/ready` - Readiness probe
- `GET /api/v1/health/live` - Liveness probe

### Metrics

Monitor these key metrics:
- Request latency
- Processing time per video
- Model inference time
- Memory usage
- GPU utilization (if applicable)
- Error rates

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For questions and support:
- Create an issue on GitHub
- Check the documentation
- Review the API documentation at `/docs` 