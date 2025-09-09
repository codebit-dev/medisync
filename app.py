from flask import Flask
from flask_cors import CORS
from config import config
from src.extensions import db, migrate


def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    CORS(app, resources={r"/*": {"origins": app.config.get('CORS_ORIGINS', ['*'])}})

    # Register blueprints
    from src.api import api_bp
    app.register_blueprint(api_bp, url_prefix='/')
    
    # Register simple endpoints (without Flask-RESTX)
    from src.api.endpoints import api_simple
    app.register_blueprint(api_simple, url_prefix='/')

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=5000)

