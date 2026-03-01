from flask import Flask, request, jsonify
import logging, os, uuid

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

PRODUCTS_DB = {
    "p1": {"id": "p1", "name": "Laptop Pro 15",   "price": 1299.99, "stock": 50,  "category": "electronics"},
    "p2": {"id": "p2", "name": "Wireless Mouse",   "price": 29.99,  "stock": 200, "category": "accessories"},
    "p3": {"id": "p3", "name": "USB-C Hub",        "price": 49.99,  "stock": 150, "category": "accessories"},
    "p4": {"id": "p4", "name": "4K Monitor",       "price": 599.99, "stock": 30,  "category": "electronics"},
}

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "product-service"}), 200

@app.route('/ready')
def ready():
    return jsonify({"status": "ready"}), 200

@app.route('/products', methods=['GET'])
def get_products():
    category = request.args.get('category')
    products = list(PRODUCTS_DB.values())
    if category:
        products = [p for p in products if p['category'] == category]
    return jsonify({"products": products, "total": len(products)}), 200

@app.route('/products/<product_id>', methods=['GET'])
def get_product(product_id):
    product = PRODUCTS_DB.get(product_id)
    if not product:
        return jsonify({"error": "Product not found"}), 404
    return jsonify(product), 200

@app.route('/products', methods=['POST'])
def create_product():
    data = request.get_json()
    if not data:
        return jsonify({"error": "Request body required"}), 400
    for f in ["name", "price", "stock", "category"]:
        if f not in data:
            return jsonify({"error": f"Missing field: {f}"}), 400
    new_id = f"p{str(uuid.uuid4())[:6]}"
    product = {"id": new_id, "name": data["name"], "price": float(data["price"]),
               "stock": int(data["stock"]), "category": data["category"]}
    PRODUCTS_DB[new_id] = product
    return jsonify(product), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
