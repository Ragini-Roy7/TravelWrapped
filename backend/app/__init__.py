from flask import Flask, jsonify
from flask_cors import CORS

from app.config.settings import Config
from app.routes.health import health_bp
from app.utils.errors import APIError


def create_app(test_config=None):
    app = Flask(__name__)

    # Load application configuration
    app.config.from_object(Config)

    # Allow test-specific configuration overrides
    if test_config is not None:
        app.config.update(test_config) 
        
    app.config["MAX_CONTENT_LENGTH"] = Config.MAX_CONTENT_LENGTH
    # Configure CORS
    CORS(
        app,
        resources={
            r"/api/*": {
                "origins": [app.config["FRONTEND_ORIGIN"]]
            }
        }
    )

    # Handle custom API errors globally
    @app.errorhandler(APIError)
    def handle_api_error(error):
        return jsonify({
            "status": "error",
            "error": {
                "code": error.code,
                "message": error.message
            }
        }), error.status_code

    # Register API routes
    app.register_blueprint(
        health_bp,
        url_prefix="/api/v1"
    )

    return app