#!/bin/bash
# Run the FastAPI backend
# Make sure PostgreSQL is running and .env is configured

echo "Starting Audio Dataset System Backend..."
echo "API will be available at: http://localhost:8000"
echo "API docs at: http://localhost:8000/docs"
echo ""

# Install dependencies if needed
pip install -r requirements.txt

# Start server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
