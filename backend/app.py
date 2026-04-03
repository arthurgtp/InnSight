from flask import Flask, jsonify, request, abort
from datetime import datetime
import uuid

app = Flask(__name__)

# ---------------------------------------------------------------------------
# In-memory data store (refleja el schema real de InnSight en Supabase)
# ---------------------------------------------------------------------------

hotels = [
    {
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "name": "Hotel InnSight Centro",
        "location": "Ciudad de Mexico, CDMX",
        "latitude": 19.4326,
        "longitude": -99.1332,
        "description": "Hotel boutique en el corazon de la ciudad.",
        "rating": 4.5,
        "amenities": ["WiFi", "Gym", "Pool", "Spa"],
        "image_url": "",
        "created_at": "2024-01-01T00:00:00Z",
    },
    {
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000002",
        "name": "Hotel InnSight Playa",
        "location": "Cancun, Quintana Roo",
        "latitude": 21.1619,
        "longitude": -86.8515,
        "description": "Resort frente al mar Caribe.",
        "rating": 4.8,
        "amenities": ["WiFi", "Pool", "Beach Access", "All Inclusive"],
        "image_url": "",
        "created_at": "2024-01-02T00:00:00Z",
    },
]

rooms = [
    {
        "room_id": "b2c3d4e5-0000-0000-0000-000000000001",
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "room_number": "101",
        "room_type": "single",
        "price": 850.00,
        "capacity": 1,
        "description": "Habitacion individual con vista a la ciudad.",
        "amenities": ["WiFi", "TV", "AC"],
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
    },
    {
        "room_id": "b2c3d4e5-0000-0000-0000-000000000002",
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000001",
        "room_number": "201",
        "room_type": "suite",
        "price": 2500.00,
        "capacity": 2,
        "description": "Suite ejecutiva con sala y jacuzzi.",
        "amenities": ["WiFi", "TV", "AC", "Jacuzzi", "Mini Bar"],
        "is_active": True,
        "created_at": "2024-01-01T00:00:00Z",
    },
    {
        "room_id": "b2c3d4e5-0000-0000-0000-000000000003",
        "hotel_id": "a1b2c3d4-0000-0000-0000-000000000002",
        "room_number": "301",
        "room_type": "deluxe",
        "price": 3200.00,
        "capacity": 3,
        "description": "Suite deluxe con vista al mar.",
        "amenities": ["WiFi", "TV", "AC", "Balcony", "Ocean View"],
        "is_active": True,
        "created_at": "2024-01-02T00:00:00Z",
    },
]

reservations = [
    {
        "reservation_id": "c3d4e5f6-0000-0000-0000-000000000001",
        "room_id": "b2c3d4e5-0000-0000-0000-000000000001",
        "client_id": "user-uuid-001",
        "start_date": "2024-06-01",
        "end_date": "2024-06-05",
        "status": "confirmed",
        "total_price": 3400.00,
        "guest_count": 1,
        "special_requests": "",
        "created_at": "2024-05-01T00:00:00Z",
    }
]

VALID_STATUSES = ["confirmed", "checked_in", "checked_out", "completed", "cancelled", "no_show"]
VALID_ROOM_TYPES = ["single", "double", "suite", "deluxe", "presidential"]


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "InnSight API", "timestamp": datetime.utcnow().isoformat()})


# ---------------------------------------------------------------------------
# Hotels
# ---------------------------------------------------------------------------

@app.route("/api/hotels", methods=["GET"])
def get_hotels():
    return jsonify(hotels), 200


@app.route("/api/hotels/<hotel_id>", methods=["GET"])
def get_hotel(hotel_id):
    hotel = next((h for h in hotels if h["hotel_id"] == hotel_id), None)
    if not hotel:
        abort(404, description="Hotel no encontrado.")
    return jsonify(hotel), 200


@app.route("/api/hotels", methods=["POST"])
def create_hotel():
    data = request.get_json()
    if not data or not data.get("name") or not data.get("location"):
        abort(400, description="Los campos 'name' y 'location' son requeridos.")

    new_hotel = {
        "hotel_id": str(uuid.uuid4()),
        "name": data["name"],
        "location": data["location"],
        "latitude": data.get("latitude"),
        "longitude": data.get("longitude"),
        "description": data.get("description", ""),
        "rating": data.get("rating", 0.0),
        "amenities": data.get("amenities", []),
        "image_url": data.get("image_url", ""),
        "created_at": datetime.utcnow().isoformat(),
    }
    hotels.append(new_hotel)
    return jsonify(new_hotel), 201


# ---------------------------------------------------------------------------
# Rooms
# ---------------------------------------------------------------------------

@app.route("/api/hotels/<hotel_id>/rooms", methods=["GET"])
def get_rooms_by_hotel(hotel_id):
    hotel = next((h for h in hotels if h["hotel_id"] == hotel_id), None)
    if not hotel:
        abort(404, description="Hotel no encontrado.")
    hotel_rooms = [r for r in rooms if r["hotel_id"] == hotel_id and r["is_active"]]
    return jsonify(hotel_rooms), 200


@app.route("/api/rooms/<room_id>", methods=["GET"])
def get_room(room_id):
    room = next((r for r in rooms if r["room_id"] == room_id), None)
    if not room:
        abort(404, description="Habitacion no encontrada.")
    return jsonify(room), 200


@app.route("/api/rooms", methods=["POST"])
def create_room():
    data = request.get_json()
    required = ["hotel_id", "room_number", "price"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        abort(400, description=f"Campos requeridos faltantes: {', '.join(missing)}")

    if not any(h["hotel_id"] == data["hotel_id"] for h in hotels):
        abort(404, description="Hotel no encontrado.")

    if data.get("room_type") and data["room_type"] not in VALID_ROOM_TYPES:
        abort(400, description=f"Tipo de habitacion invalido. Valores validos: {VALID_ROOM_TYPES}")

    new_room = {
        "room_id": str(uuid.uuid4()),
        "hotel_id": data["hotel_id"],
        "room_number": data["room_number"],
        "room_type": data.get("room_type", "single"),
        "price": float(data["price"]),
        "capacity": data.get("capacity", 2),
        "description": data.get("description", ""),
        "amenities": data.get("amenities", []),
        "is_active": True,
        "created_at": datetime.utcnow().isoformat(),
    }
    rooms.append(new_room)
    return jsonify(new_room), 201


# ---------------------------------------------------------------------------
# Reservations
# ---------------------------------------------------------------------------

@app.route("/api/reservations", methods=["GET"])
def get_reservations():
    return jsonify(reservations), 200


@app.route("/api/reservations/<reservation_id>", methods=["GET"])
def get_reservation(reservation_id):
    res = next((r for r in reservations if r["reservation_id"] == reservation_id), None)
    if not res:
        abort(404, description="Reservacion no encontrada.")
    return jsonify(res), 200


@app.route("/api/reservations", methods=["POST"])
def create_reservation():
    data = request.get_json()
    required = ["room_id", "client_id", "start_date", "end_date", "total_price"]
    missing = [f for f in required if not data.get(f)]
    if missing:
        abort(400, description=f"Campos requeridos faltantes: {', '.join(missing)}")

    if not any(r["room_id"] == data["room_id"] for r in rooms):
        abort(404, description="Habitacion no encontrada.")

    if data["start_date"] >= data["end_date"]:
        abort(400, description="La fecha de salida debe ser posterior a la de entrada.")

    new_reservation = {
        "reservation_id": str(uuid.uuid4()),
        "room_id": data["room_id"],
        "client_id": data["client_id"],
        "start_date": data["start_date"],
        "end_date": data["end_date"],
        "status": "confirmed",
        "total_price": float(data["total_price"]),
        "guest_count": data.get("guest_count", 1),
        "special_requests": data.get("special_requests", ""),
        "created_at": datetime.utcnow().isoformat(),
    }
    reservations.append(new_reservation)
    return jsonify(new_reservation), 201


@app.route("/api/reservations/<reservation_id>/status", methods=["PATCH"])
def update_reservation_status(reservation_id):
    res = next((r for r in reservations if r["reservation_id"] == reservation_id), None)
    if not res:
        abort(404, description="Reservacion no encontrada.")

    data = request.get_json()
    new_status = data.get("status")
    if new_status not in VALID_STATUSES:
        abort(400, description=f"Estado invalido. Valores validos: {VALID_STATUSES}")

    res["status"] = new_status
    return jsonify(res), 200


# ---------------------------------------------------------------------------
# Error handlers
# ---------------------------------------------------------------------------

@app.errorhandler(400)
def bad_request(e):
    return jsonify({"error": str(e.description)}), 400


@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": str(e.description)}), 404


@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({"error": "Metodo no permitido."}), 405


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
