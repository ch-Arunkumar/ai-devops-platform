from flask import Flask, request, jsonify
from flask_cors import CORS
import logging, os, uuid, time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

ORDERS_DB = {
    "ord1": {"id": "ord1", "user_id": "1", "product_id": "p1", "quantity": 1,
             "total_price": 1299.99, "status": "delivered"},
    "ord2": {"id": "ord2", "user_id": "2", "product_id": "p2", "quantity": 2,
             "total_price": 59.98, "status": "processing"},
}

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "order-service"}), 200

@app.route('/ready')
def ready():
    return jsonify({"status": "ready"}), 200

@app.route('/orders', methods=['GET'])
def get_orders():
    user_id = request.args.get('user_id')
    orders = list(ORDERS_DB.values())
    if user_id:
        orders = [o for o in orders if o['user_id'] == user_id]
    return jsonify({"orders": orders, "total": len(orders)}), 200

@app.route('/orders/<order_id>', methods=['GET'])
def get_order(order_id):
    order = ORDERS_DB.get(order_id)
    if not order:
        return jsonify({"error": "Order not found"}), 404
    return jsonify(order), 200

@app.route('/orders', methods=['POST'])
def create_order():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    for f in ["user_id", "product_id", "quantity"]:
        if f not in data:
            return jsonify({"error": f"Missing field: {f}"}), 400
    if int(data['quantity']) <= 0:
        return jsonify({"error": "Quantity must be greater than 0"}), 400
    new_id = f"ord{str(uuid.uuid4())[:6]}"
    order = {"id": new_id, "user_id": str(data['user_id']),
             "product_id": str(data['product_id']),
             "quantity": int(data['quantity']),
             "total_price": round(99.99 * int(data['quantity']), 2),
             "status": "pending"}
    ORDERS_DB[new_id] = order
    return jsonify(order), 201

@app.route('/orders/<order_id>/status', methods=['PATCH'])
def update_status(order_id):
    order = ORDERS_DB.get(order_id)
    if not order:
        return jsonify({"error": "Order not found"}), 404
    data = request.get_json()
    valid = ["pending", "processing", "shipped", "delivered", "cancelled"]
    if data.get('status') not in valid:
        return jsonify({"error": f"Invalid status. Use: {valid}"}), 400
    order['status'] = data['status']
    return jsonify(order), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002)
