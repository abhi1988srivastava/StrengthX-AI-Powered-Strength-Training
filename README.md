
# StrengthX – AI-Powered Strength Training App

## Overview
StrengthX is a minimalist workout app that generates AI-based personalized strength training workouts, allows users to upload workout images for parsing, and works completely offline with local storage.

---

## Features
- Workout Modes: Full Body, Push-Pull, Bro-Split, Individual Muscle Group
- Focus Percentage Selection for Muscle Groups
- Equipment-based Filtering
- ML-powered Workout Generator
- OCR Image Parsing (Sets/Reps/Muscle Group)
- SwiftUI-based iOS App with MVVM Architecture
- No login/signup (Local-Only Experience)

---

## Project Structure
- `/backend` - FastAPI app with ML and OCR logic
- `/ios-app` - SwiftUI app using MVVM
- `README.md` - Setup guide
- `Dockerfile` - Backend container support

---

## Setup

### Backend
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload
```

### iOS App
1. Open `ios-app` in Xcode
2. Build and run the SwiftUI project
3. No login required

---

## Docker (Optional)
```bash
cd backend
docker build -t strengthx-backend .
docker run -p 8000:8000 strengthx-backend
```

---

MIT License | Made with 💪 for serious lifters.
