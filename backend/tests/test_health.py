
from app import create_app


def test_health_endpoint_returns_success_and_allows_frontend_origin():
    app = create_app({
        "TESTING": True,
        "FRONTEND_ORIGIN": "http://localhost:3000"
    })

    response = app.test_client().get(
        "/api/v1/health",
        headers={"Origin": "http://localhost:3000"},
    )

    assert response.status_code == 200

    assert response.get_json() == {
        "status": "success",
        "data": {
            "service": "travel-wrapped-api"
        },
    }

    assert response.headers["Access-Control-Allow-Origin"] == (
        "http://localhost:3000"
    )
