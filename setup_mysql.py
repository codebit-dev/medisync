#!/usr/bin/env python3
"""
MySQL Database Setup Script for MEDISYNC
Creates the database and initializes the schema
"""

import pymysql
import os
from dotenv import load_dotenv

load_dotenv()

def create_database():
    """Create the MySQL database if it doesn't exist"""
    
    # Get configuration from environment variables
    host = os.getenv('MYSQL_HOST', 'localhost')
    port = int(os.getenv('MYSQL_PORT', 3306))
    user = os.getenv('MYSQL_USER', 'root')
    password = os.getenv('MYSQL_PASSWORD', '')
    database = os.getenv('MYSQL_DATABASE', 'medisync')
    
    try:
        # Connect to MySQL server (without specifying database)
        connection = pymysql.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        
        with connection.cursor() as cursor:
            # Create database if it doesn't exist
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{database}` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
            print(f"✓ Database '{database}' created or already exists")
            
            # Grant privileges (optional - if using different user)
            # cursor.execute(f"GRANT ALL PRIVILEGES ON `{database}`.* TO '{user}'@'localhost'")
            # cursor.execute("FLUSH PRIVILEGES")
            
        connection.commit()
        connection.close()
        
        return True
        
    except pymysql.Error as e:
        print(f"✗ MySQL Error: {e}")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def init_schema():
    """Initialize database schema using Flask-Migrate"""
    try:
        import subprocess
        
        # Initialize migrations
        print("\nInitializing database migrations...")
        subprocess.run(["flask", "db", "init"], check=False)
        
        # Create initial migration
        print("\nCreating initial migration...")
        subprocess.run(["flask", "db", "migrate", "-m", "Initial migration for MySQL"], check=True)
        
        # Apply migration
        print("\nApplying migration...")
        subprocess.run(["flask", "db", "upgrade"], check=True)
        
        print("✓ Database schema initialized successfully")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"✗ Migration Error: {e}")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_connection():
    """Test the database connection"""
    try:
        from app import create_app
        from src.models import db
        
        app = create_app()
        with app.app_context():
            # Test query
            result = db.session.execute(db.text("SELECT 1"))
            print("✓ Database connection test successful")
            return True
            
    except Exception as e:
        print(f"✗ Connection test failed: {e}")
        return False

if __name__ == "__main__":
    print("MEDISYNC MySQL Database Setup")
    print("=" * 50)
    
    # Check MySQL credentials
    print("\nMySQL Configuration:")
    print(f"  Host: {os.getenv('MYSQL_HOST', 'localhost')}")
    print(f"  Port: {os.getenv('MYSQL_PORT', 3306)}")
    print(f"  User: {os.getenv('MYSQL_USER', 'root')}")
    print(f"  Database: {os.getenv('MYSQL_DATABASE', 'medisync')}")
    
    # Create database
    print("\n1. Creating database...")
    if not create_database():
        print("\n⚠ Failed to create database. Please check your MySQL credentials.")
        print("Make sure MySQL server is running and accessible.")
        exit(1)
    
    # Initialize schema
    print("\n2. Initializing database schema...")
    if not init_schema():
        print("\n⚠ Failed to initialize schema.")
        print("You can manually run:")
        print("  flask db init")
        print("  flask db migrate -m 'Initial migration'")
        print("  flask db upgrade")
    
    # Test connection
    print("\n3. Testing database connection...")
    test_connection()
    
    print("\n" + "=" * 50)
    print("Setup complete! You can now run the application.")
    print("\nTo start the backend server:")
    print("  python app.py")
    print("\nTo start the frontend:")
    print("  cd medisync-frontend")
    print("  npm start")
