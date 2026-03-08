from flask import Flask, request, jsonify
from flask_cors import CORS
import logging, os, uuid

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

USERS_DB = {
    "1": {"id": "1", "name": "Alice Johnson", "email": "alice@example.com", "role": "admin"},
    "2": {"id": "2", "name": "Bob Smith",     "email": "bob@example.com",   "role": "user"},
    "3": {"id": "3", "name": "Carol White",   "email": "carol@example.com", "role": "user"},
}

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "user-service"}), 200

@app.route('/ready')
def ready():
    return jsonify({"status": "ready"}), 200

@app.route('/users', methods=['GET'])
def get_users():
    users = list(USERS_DB.values())
    return jsonify({"users": users, "total": len(users), "service": "user-service"}), 200

@app.route('/users/<user_id>', methods=['GET'])
def get_user(user_id):
    user = USERS_DB.get(user_id)
    if not user:
        return jsonify({"error": "User not found"}), 404
    return jsonify(user), 200

@app.route('/users', methods=['POST'])
def create_user():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    for f in ["name", "email", "password"]:
        if f not in data:
            return jsonify({"error": f"Missing field: {f}"}), 400
    if data["email"] in [u["email"] for u in USERS_DB.values()]:
        return jsonify({"error": "Email already exists"}), 409
    new_id = str(uuid.uuid4())[:8]
    user = {"id": new_id, "name": data["name"], "email": data["email"], "role": "user"}
    USERS_DB[new_id] = user
    return jsonify(user), 201

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    if user_id not in USERS_DB:
        return jsonify({"error": "User not found"}), 404
    del USERS_DB[user_id]
    return jsonify({"message": "User deleted"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
