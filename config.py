import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Base configuration."""
    
    # Flask
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    DEBUG = False
    TESTING = False
    
    # Database - MySQL Configuration
    # Format: mysql+pymysql://username:password@localhost:port/database_name
    MYSQL_USER = os.environ.get('MYSQL_USER', 'root')
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD', '')
    MYSQL_HOST = os.environ.get('MYSQL_HOST', 'localhost')
    MYSQL_PORT = os.environ.get('MYSQL_PORT', '3306')
    MYSQL_DATABASE = os.environ.get('MYSQL_DATABASE', 'medisync')
    
    # Try to use MySQL, fallback to SQLite if MySQL is not available
    USE_SQLITE = os.environ.get('USE_SQLITE', 'false').lower() == 'true'
    
    if USE_SQLITE:
        # Use SQLite for development/testing
        SQLALCHEMY_DATABASE_URI = 'sqlite:///medisync.db'
    else:
        # Build MySQL connection string
        if MYSQL_PASSWORD:
            SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}?charset=utf8mb4'
        else:
            SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DATABASE}?charset=utf8mb4'
    
    # Override with environment variable if provided
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', SQLALCHEMY_DATABASE_URI)
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True
    }
    
    # FHIR
    FHIR_BASE_URL = os.environ.get('FHIR_BASE_URL', 'http://localhost:5000/fhir')
    FHIR_VERSION = 'R4'
    
    # WHO ICD-11 API
    ICD11_API_BASE_URL = 'https://id.who.int/icd'
    ICD11_CLIENT_ID = os.environ.get('ICD11_CLIENT_ID')
    ICD11_CLIENT_SECRET = os.environ.get('ICD11_CLIENT_SECRET')
    ICD11_TOKEN_ENDPOINT = 'https://icdaccessmanagement.who.int/connect/token'
    
    # OAuth 2.0 / ABHA
    ABHA_AUTH_URL = os.environ.get('ABHA_AUTH_URL', 'https://healthidsbx.abdm.gov.in/api/v1/auth')
    ABHA_CLIENT_ID = os.environ.get('ABHA_CLIENT_ID')
    ABHA_CLIENT_SECRET = os.environ.get('ABHA_CLIENT_SECRET')
    TOKEN_EXPIRY_HOURS = 24
    
    # Elasticsearch (optional for scalable search)
    ELASTICSEARCH_URL = os.environ.get('ELASTICSEARCH_URL')
    
    # Audit & Compliance
    ENABLE_AUDIT_LOGGING = True
    AUDIT_LOG_RETENTION_DAYS = 365
    
    # ISO 22600 Compliance
    CONSENT_REQUIRED = True
    VERSION_CONTROL_ENABLED = True
    
    # API Rate Limiting
    RATELIMIT_ENABLED = True
    RATELIMIT_DEFAULT = "100/hour"
    
    # CORS
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*').split(',')
    
class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True
    SQLALCHEMY_ECHO = True
    
class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False
    TESTING = False
    
class TestingConfig(Config):
    """Testing configuration."""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'
    
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
