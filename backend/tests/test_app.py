import pytest
import json
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------

def test_health(client):
    res = client.get("/api/health")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "ok"
    assert data["service"] == "InnSight API"


# ---------------------------------------------------------------------------
# Hotels
# ---------------------------------------------------------------------------

def test_get_hotels(client):
    res = client.get("/api/hotels")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert isinstance(data, list)
    assert len(data) >= 1


def test_get_hotel_by_id(client):
    res = client.get("/api/hotels/a1b2c3d4-0000-0000-0000-000000000001")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["name"] == "Hotel InnSight Centro"


def test_get_hotel_not_found(client):
    res = client.get("/api/hotels/hotel-inexistente")
    assert res.status_code == 404


def test_create_hotel(client):
    payload = {
        "name": "Hotel Test Norte",
        "location": "Monterrey, NL",
        "description": "Hotel de prueba.",
        "rating": 4.0,
        "amenities": ["WiFi", "Pool"],
    }
    res = client.post(
        "/api/hotels",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert res.status_code == 201
    data = json.loads(res.data)
    assert data["name"] == "Hotel Test Norte"
    assert "hotel_id" in data


def test_create_hotel_missing_fields(client):
    res = client.post(
        "/api/hotels",
        data=json.dumps({"name": "Sin ubicacion"}),
        content_type="application/json",
    )
    assert res.status_code == 400


# ---------------------------------------------------------------------------
# Rooms
# ---------------------------------------------------------------------------

def test_get_rooms_by_hotel(client):
    res = client.get("/api/hotels/a1b2c3d4-0000-0000-0000-000000000001/rooms")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert isinstance(data, list)
    assert len(data) >= 1


def test_get_rooms_hotel_not_found(client):
    res = client.get("/api/hotels/hotel-inexistente/rooms")
    assert res.status_code == 404


def test_get_room_by_id(client):
    res = client.get("/api/rooms/b2c3d4e5-0000-0000-0000-000000000001")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["room_number"] == "101"


def test_get_room_not_found(client):
    res = client.get("/api/rooms/room-inexistente")
    assert res.status_code == 404


def test_create_room(client):
    payload = {
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "room_number": "505",
        "room_type": "double",
        "price": 1200.00,
        "capacity": 2,
        "description": "Habitacion doble de prueba.",
        "amenities": ["WiFi", "TV"],
    }
    res = client.post(
        "/api/rooms",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert res.status_code == 201
    data = json.loads(res.data)
    assert data["room_number"] == "505"
    assert data["room_type"] == "double"


def test_create_room_invalid_type(client):
    payload = {
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "room_number": "606",
        "room_type": "penthouse",
        "price": 5000.00,
    }
    res = client.post(
        "/api/rooms",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert res.status_code == 400


def test_create_room_missing_fields(client):
    res = client.post(
        "/api/rooms",
        data=json.dumps({"room_number": "707"}),
        content_type="application/json",
    )
    assert res.status_code == 400


# ---------------------------------------------------------------------------
# Reservations
# ---------------------------------------------------------------------------

def test_get_reservations(client):
    res = client.get("/api/reservations")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert isinstance(data, list)


def test_get_reservation_by_id(client):
    res = client.get("/api/reservations/c3d4e5f6-0000-0000-0000-000000000001")
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "confirmed"


def test_get_reservation_not_found(client):
    res = client.get("/api/reservations/reservacion-inexistente")
    assert res.status_code == 404


def test_create_reservation(client):
    payload = {
        "room_id": "b2c3d4e5-0000-0000-0000-000000000002",
        "client_id": "user-uuid-002",
        "start_date": "2024-07-10",
        "end_date": "2024-07-15",
        "total_price": 12500.00,
        "guest_count": 2,
        "special_requests": "Vista a la ciudad por favor.",
    }
    res = client.post(
        "/api/reservations",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert res.status_code == 201
    data = json.loads(res.data)
    assert data["status"] == "confirmed"
    assert data["guest_count"] == 2


def test_create_reservation_invalid_dates(client):
    payload = {
        "room_id": "b2c3d4e5-0000-0000-0000-000000000001",
        "client_id": "user-uuid-003",
        "start_date": "2024-07-15",
        "end_date": "2024-07-10",
        "total_price": 850.00,
    }
    res = client.post(
        "/api/reservations",
        data=json.dumps(payload),
        content_type="application/json",
    )
    assert res.status_code == 400


def test_create_reservation_missing_fields(client):
    res = client.post(
        "/api/reservations",
        data=json.dumps({"client_id": "user-uuid-004"}),
        content_type="application/json",
    )
    assert res.status_code == 400


def test_update_reservation_status(client):
    res = client.patch(
        "/api/reservations/c3d4e5f6-0000-0000-0000-000000000001/status",
        data=json.dumps({"status": "checked_in"}),
        content_type="application/json",
    )
    assert res.status_code == 200
    data = json.loads(res.data)
    assert data["status"] == "checked_in"


def test_update_reservation_status_invalid(client):
    res = client.patch(
        "/api/reservations/c3d4e5f6-0000-0000-0000-000000000001/status",
        data=json.dumps({"status": "volando"}),
        content_type="application/json",
    )
    assert res.status_code == 400


def test_update_reservation_not_found(client):
    res = client.patch(
        "/api/reservations/no-existe/status",
        data=json.dumps({"status": "cancelled"}),
        content_type="application/json",
    )
    assert res.status_code == 404
