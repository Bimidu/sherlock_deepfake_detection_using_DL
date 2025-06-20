# Sherlock - AI-Powered Deepfake Video Detection

**Sherlock** is a cross-platform mobile application that detects AI-generated (deepfake) videos using advanced machine learning techniques. The application consists of a Flutter frontend for mobile devices and a FastAPI backend for video processing and inference.

## 🏗️ Architecture Overview

```
┌─────────────────┐    HTTP/REST API    ┌─────────────────┐
│                 │◄───────────────────►│                 │
│  Flutter App    │     (JSON/Video)    │  FastAPI Server │
│  (Frontend)     │                     │   (Backend)     │
│                 │                     │                 │
│ • Video Upload  │                     │ • Frame Extract │
│ • Progress UI   │                     │ • ML Inference  │
│ • Results View  │                     │ • Aggregation   │
└─────────────────┘                     └─────────────────┘
                                               │
                                               ▼
                                        ┌─────────────────┐
                                        │   ML Models     │
                                        │ • XceptionNet   │
                                        │ • MesoNet       │
                                        │ • Custom Models │
                                        └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (>= 3.0.0)
- **Python** (>= 3.8)
- **Docker** (optional, for containerized deployment)

### 1. Backend Setup

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Frontend Setup

```bash
cd frontend
flutter pub get
flutter run
```

### 3. Docker Deployment (Optional)

```bash
cd backend
docker build -t sherlock-backend .
docker run -p 8000:8000 sherlock-backend
```

## 📱 Features

### Frontend (Flutter)
- **Cross-platform** mobile support (iOS & Android)
- **Video upload** from gallery or file system
- **Real-time progress** indicators during upload/processing
- **Results visualization** with confidence scores
- **Suspicious frame** highlighting and timestamps
- **Clean Material Design** UI with intuitive navigation

### Backend (FastAPI)
- **RESTful API** with automatic documentation
- **Video frame extraction** using OpenCV
- **ML model inference** with multiple model support
- **Result aggregation** with confidence scoring
- **CORS support** for cross-origin requests
- **Input validation** for video format and size
- **Modular architecture** for easy model swapping

## 🧠 Detection Models

Sherlock supports multiple state-of-the-art deepfake detection models:

1. **XceptionNet**: High accuracy for general deepfake detection
2. **MesoNet**: Lightweight model for real-time inference
3. **Custom Models**: Easy integration of your own trained models

## 📊 API Endpoints

- `POST /upload`: Upload video for analysis
- `GET /results/{task_id}`: Get analysis results
- `GET /health`: Health check endpoint
- `GET /docs`: Interactive API documentation

## 🔒 Security & Privacy

- Videos are processed locally and not stored permanently
- Secure file upload with size and format validation
- HTTPS communication between frontend and backend
- Optional API key authentication

## 🛠️ Development

### Adding New Models

1. Place your model in `backend/models/`
2. Create a detector class inheriting from `BaseDetector`
3. Register the model in `backend/core/model_manager.py`

### Frontend State Management

The app uses **Provider** for state management with clean separation of concerns:
- `VideoUploadProvider`: Handles upload logic
- `ResultsProvider`: Manages detection results
- `SettingsProvider`: App configuration

## 📋 Project Structure

```
sherlock/
├── backend/                 # FastAPI backend
│   ├── api/                # API routes
│   ├── core/               # Core business logic
│   ├── models/             # ML models
│   ├── services/           # Processing services
│   ├── utils/              # Utilities
│   ├── Dockerfile          # Container configuration
│   └── requirements.txt    # Python dependencies
├── frontend/               # Flutter frontend
│   ├── lib/
│   │   ├── models/         # Data models
│   │   ├── providers/      # State management
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API services
│   │   ├── utils/          # Utilities
│   │   └── widgets/        # Reusable widgets
│   └── pubspec.yaml        # Flutter dependencies
└── README.md               # This file
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For questions and support, please open an issue on GitHub or contact the development team. 