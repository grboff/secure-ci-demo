from flask import Flask, jsonify
import os

app = Flask(__name__)

# Функция для безопасного чтения секрета
def get_api_key():
    """
    Читаем секрет из файла (НЕ из переменной окружения!)
    В production секрет будет в /var/secrets/api_key
    В dev может не существовать
    """
    try:
        with open('/var/secrets/api_key', 'r') as f:
            return f.read().strip()
    except FileNotFoundError:
        return "NOT_SET_IN_DEV"

@app.route('/')
def root():
    return jsonify({
        "service": "Secure CI Demo",
        "version": "1.0"
    })

@app.route('/health')
def health():
    """Liveness probe"""
    return jsonify({"status": "healthy"})

@app.route('/config')
def config():
    """
    Показываем конфигурацию БЕЗ раскрытия секретов
    НИКОГДА не возвращаем реальный API key!
    """
    api_key = get_api_key()
    return jsonify({
        "api_key_configured": api_key != "NOT_SET_IN_DEV",
        "api_key_preview": api_key[:4] + "..." if api_key != "NOT_SET_IN_DEV" else "NOT_SET",
        "version": "1.0"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
