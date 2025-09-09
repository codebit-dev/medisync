# MySQL Setup Guide for MEDISYNC

## Prerequisites

1. **Install MySQL Server** (if not already installed):
   - Download from: https://dev.mysql.com/downloads/mysql/
   - For Windows: MySQL Installer includes MySQL Server, Workbench, and other tools
   - For Ubuntu/Debian: `sudo apt-get install mysql-server`
   - For macOS: `brew install mysql`

2. **Start MySQL Service**:
   - Windows: 
     ```powershell
     # Check if MySQL service is running
     Get-Service -Name "MySQL*"
     
     # Start MySQL service
     Start-Service -Name "MySQL80"  # or MySQL57, MySQL56 depending on version
     ```
   - Linux/macOS: 
     ```bash
     sudo systemctl start mysql  # or
     sudo service mysql start
     ```

## Configuration Steps

### 1. Update Environment Variables

Edit the `.env` file in the project root with your MySQL credentials:

```env
# MySQL Database Configuration
MYSQL_USER=root
MYSQL_PASSWORD=your_password_here
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=medisync
```

### 2. Create Database (Manual Method)

If the automatic setup doesn't work, you can create the database manually:

```sql
-- Connect to MySQL
mysql -u root -p

-- Create database
CREATE DATABASE IF NOT EXISTS medisync 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- Create a dedicated user (optional but recommended)
CREATE USER IF NOT EXISTS 'medisync_user'@'localhost' 
IDENTIFIED BY 'secure_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON medisync.* TO 'medisync_user'@'localhost';
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES;
USE medisync;
```

### 3. Run Automated Setup

After MySQL is running and configured:

```bash
# Install Python dependencies
pip install -r requirements.txt

# Run the setup script
python setup_mysql.py
```

### 4. Initialize Database Schema

If the automatic migration fails, run these commands manually:

```bash
# Set Flask app environment variable
export FLASK_APP=app.py  # On Windows: set FLASK_APP=app.py

# Initialize migrations
flask db init

# Create initial migration
flask db migrate -m "Initial migration for MySQL"

# Apply migrations
flask db upgrade
```

## Troubleshooting

### Connection Refused Error

If you get "Can't connect to MySQL server" error:

1. **Check if MySQL is running**:
   ```powershell
   # Windows
   Get-Service -Name "MySQL*"
   
   # Linux/macOS
   systemctl status mysql
   ```

2. **Check MySQL port**:
   ```bash
   netstat -an | findstr :3306  # Windows
   netstat -an | grep 3306      # Linux/macOS
   ```

3. **Test connection**:
   ```bash
   mysql -u root -p -h localhost -P 3306
   ```

### Authentication Issues

If you have authentication problems:

1. **For MySQL 8.0+ with authentication plugin issues**:
   ```sql
   ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password';
   FLUSH PRIVILEGES;
   ```

2. **Reset root password** (if forgotten):
   - Windows: Use MySQL Installer to reconfigure
   - Linux/macOS: Follow MySQL documentation for password reset

### Character Set Issues

If you encounter character encoding problems:

```sql
-- Check database character set
SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME = 'medisync';

-- Fix if needed
ALTER DATABASE medisync 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
```

## Verification

After successful setup, verify the installation:

```python
# Test connection script
python -c "
from app import create_app
from src.models import db
app = create_app()
with app.app_context():
    result = db.session.execute(db.text('SELECT 1'))
    print('✓ Database connection successful')
"
```

## Database Backup & Restore

### Backup
```bash
mysqldump -u root -p medisync > medisync_backup.sql
```

### Restore
```bash
mysql -u root -p medisync < medisync_backup.sql
```

## Performance Optimization

For production deployment, consider these MySQL settings in `my.cnf` or `my.ini`:

```ini
[mysqld]
# Character set
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# InnoDB settings
innodb_buffer_pool_size=1G
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT

# Connection settings
max_connections=200
max_allowed_packet=64M

# Query cache (MySQL < 8.0)
query_cache_size=128M
query_cache_type=1
```

## Next Steps

After successful MySQL setup:

1. **Start the backend server**:
   ```bash
   python app.py
   ```

2. **Start the frontend** (in a new terminal):
   ```bash
   cd medisync-frontend
   npm start
   ```

3. **Access the application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000
   - API Documentation: http://localhost:5000/docs

## Support

If you continue to face issues:

1. Check the Flask app logs for detailed error messages
2. Verify your MySQL installation and version: `mysql --version`
3. Ensure firewall/antivirus isn't blocking port 3306
4. Check MySQL error logs:
   - Windows: `C:\ProgramData\MySQL\MySQL Server X.X\Data\*.err`
   - Linux: `/var/log/mysql/error.log`
   - macOS: `/usr/local/var/mysql/*.err`
