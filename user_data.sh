#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

# 1. Install dependencies
dnf update -y
dnf install python3-pip -y
pip3 install flask flask-sqlalchemy pymysql gunicorn

# 2. Create project folder
mkdir -p /home/ec2-user/student-app

# 3. Write config.py
python3 << 'PYEOF'
content = """import os
class Config:
    SQLALCHEMY_DATABASE_URI = (
        'mysql+pymysql://'
        + (os.environ.get('DB_USER')     or '') + ':'
        + (os.environ.get('DB_PASSWORD') or '') + '@'
        + (os.environ.get('DB_HOST')     or '') + '/'
        + (os.environ.get('DB_NAME')     or 'studentdb')
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
"""
with open('/home/ec2-user/student-app/config.py', 'w') as f:
    f.write(content)
PYEOF

# 4. Write app.py
python3 << 'PYEOF'
content = """from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from config import Config
import socket

app = Flask(__name__)
app.config.from_object(Config)
db = SQLAlchemy(app)

class Student(db.Model):
    __tablename__ = 'students'
    id     = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name   = db.Column(db.String(100), nullable=False)
    email  = db.Column(db.String(120), unique=True, nullable=False)
    course = db.Column(db.String(100), default='General')
    def to_dict(self):
        return {'id': self.id, 'name': self.name,
                'email': self.email, 'course': self.course}

with app.app_context():
    db.create_all()

@app.route('/')
def home():
    return jsonify({'message': 'Student API running!',
                    'server': socket.gethostname()})

@app.route('/students', methods=['GET'])
def get_all():
    return jsonify([s.to_dict() for s in Student.query.all()])

@app.route('/students', methods=['POST'])
def add_student():
    d = request.get_json()
    if not d or not d.get('name') or not d.get('email'):
        return jsonify({'error': 'name and email are required'}), 400
    if Student.query.filter_by(email=d['email']).first():
        return jsonify({'error': 'Email already exists'}), 409
    s = Student(name=d['name'], email=d['email'],
                course=d.get('course', 'General'))
    db.session.add(s)
    db.session.commit()
    return jsonify({'message': 'Student added!', 'student': s.to_dict()}), 201

@app.route('/students/<int:sid>', methods=['GET'])
def get_one(sid):
    s = db.session.get(Student, sid)
    return jsonify(s.to_dict()) if s else (jsonify({'error': 'Not found'}), 404)

@app.route('/students/<int:sid>', methods=['DELETE'])
def delete_student(sid):
    s = db.session.get(Student, sid)
    if not s:
        return jsonify({'error': 'Not found'}), 404
    db.session.delete(s)
    db.session.commit()
    return jsonify({'message': f'Student {sid} deleted'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
"""
with open('/home/ec2-user/student-app/app.py', 'w') as f:
    f.write(content)
PYEOF

# 5. Write systemd service
cat > /etc/systemd/system/student-app.service << EOF
[Unit]
Description=Student Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/home/ec2-user/student-app
Environment="DB_HOST=${db_host}"
Environment="DB_USER=${db_user}"
Environment="DB_NAME=${db_name}"
Environment="DB_PASSWORD=${db_password}"
ExecStart=/usr/local/bin/gunicorn -w 2 -b 0.0.0.0:5000 app:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 6. Enable and start service
systemctl daemon-reload
systemctl enable student-app.service
systemctl start student-app.service