#!/bin/bash

# Simple script to run all steps in sequence
echo "=== RUNNING COMPLETE TEST SEQUENCE ==="
echo ""

# Ensure we're in the right directory
cd "$(dirname "$0")"

# 1. Activate virtual environment if it exists
if [ -d "venv/bin" ]; then
  echo "Activating virtual environment..."
  source venv/bin/activate
fi

# 2. Run simple test to create a model
echo ""
echo "=== CREATING TEST MODEL ==="
python simple_test.py

# 3. Verify model exists
if [ -f "output_models/NotificationTimePredictor.pkl" ]; then
  echo ""
  echo "✅ Model file created successfully!"
else
  echo ""
  echo "❌ Model file not created!"
  exit 1
fi

# 4. Start server in the background
echo ""
echo "=== STARTING SERVER ==="
python simple_prediction_api.py > server.log 2>&1 &
SERVER_PID=$!

# Give the server a moment to start
sleep 3

# 5. Test the API
echo ""
echo "=== TESTING API ==="
python test_api.py

# 6. Shut down the server
echo ""
echo "=== CLEANING UP ==="
kill $SERVER_PID
echo "Server stopped."

echo ""
echo "=== TEST SEQUENCE COMPLETE ==="
