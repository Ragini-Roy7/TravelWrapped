from app import create_app
from app.utils.errors import APIError


def test_api_error_returns_standardized_json():
    app = create_app({
        "TESTING": True
    })

    def trigger_error():
        raise APIError(
            message="Unsupported image format",
            code="INVALID_FILE",
            status_code=400
        )

    app.add_url_rule(
        "/api/v1/test-error",
        view_func=trigger_error
    )

    response = app.test_client().get(
        "/api/v1/test-error"
    )

    assert response.status_code == 400

    assert response.get_json() == {
        "status": "error",
        "error": {
            "code": "INVALID_FILE",
            "message": "Unsupported image format"
        }
    }