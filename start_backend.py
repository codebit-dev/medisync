#!/usr/bin/env python
"""Start the Flask backend server"""

import os
import sys

# Add the project directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

if __name__ == '__main__':
    try:
        app = create_app('development')
        print("\n" + "="*50)
        print("MEDISYNC Backend API Server")
        print("="*50)
        print(f"Starting server at http://localhost:5000")
        print(f"API Documentation: http://localhost:5000/docs")
        print(f"Health Check: http://localhost:5000/health")
        print("="*50 + "\n")
        
        # Run the app
        app.run(host='0.0.0.0', port=5000, debug=True)
    except Exception as e:
        print(f"Error starting Flask app: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
