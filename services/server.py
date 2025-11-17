
import ssl
from flask import Flask, request, jsonify
import logging

app = Flask(__name__)

logging.basicConfig(
    filename='access.log',
    level=logging.INFO,
    format='%(asctime)s %(message)s'
)


# ====================================
#               ROUTES
# ====================================

@app.route("/user/profile")
def user_profile():
    return jsonify({
        "msg": "User profile",
        "data": {
            "name": "Demo User",
            "role": "user",
            "email": "user@example.com",
            "profile": {
                "age": 21,
                "department": "IT",
                "courses": ["Network Security", "Python", "DevOps"]
            }
        }
    }), 200

@app.route("/admin/stats")
def admin_stats():
    return jsonify({
        "msg": "Admin stats",
        "data": {
            "name": "Demo Admin",
            "role": "admin",
            "email": "admin@example.com",
            "permissions": ["manage_users", "view_stats", "block_ip"]
        },
        "system_stats": {
            "requests_today": 1833,
            "blocked_ips": 4,
            "active_users": 63
        }
    }), 200
# ====================================
#          START HTTPS mTLS
# ====================================

if __name__ == '__main__':
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile="/home/han/project/kong/certs/server.crt", keyfile="/home/han/project/kong/certs/server.key")
    context.verify_mode = ssl.CERT_REQUIRED
    context.load_verify_locations(cafile="/home/han/project/kong/certs/ca.crt")

    app.run(host='0.0.0.0', port=3000, debug=True, ssl_context=context)
