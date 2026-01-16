# syntax=docker/dockerfile:1.4
# ↑ Включаем BuildKit (нужен для secrets)

# ========================================
# Base stage - общие настройки
# ========================================
FROM python:3.11-slim AS base

# Системные зависимости (curl для healthcheck)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ========================================
# Dependencies stage - устанавливаем пакеты
# ========================================
FROM base AS dependencies

COPY requirements.txt .

# Cache mount для pip (ускоряет повторные сборки)
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-cache-dir -r requirements.txt

# ========================================
# Build stage - работа с секретами
# ========================================
FROM dependencies AS build

# ВАЖНО: Это демонстрация как использовать secrets
# В реальности здесь могло бы быть:
# - Клонирование private repo
# - Скачивание приватных артефактов
# - Аутентификация в private registry

# Монтируем секрет временно (НЕ копируем в образ!)
RUN --mount=type=secret,id=github_token \
    echo "Building with secrets..." && \
    if [ -f /run/secrets/github_token ]; then \
        echo "Secret found, length: $(cat /run/secrets/github_token | wc -c)"; \
        # Здесь могла быть команда типа:
        # TOKEN=$(cat /run/secrets/github_token) && \
        # git clone https://${TOKEN}@github.com/private/repo.git
    else \
        echo "No secret provided (это нормально для локальной сборки)"; \
    fi

# ========================================
# Final stage - минимальный образ
# ========================================
FROM base AS final

# Создаём non-root пользователя
RUN groupadd -r appuser && \
    useradd -r -g appuser appuser && \
    mkdir -p /var/secrets && \
    chown -R appuser:appuser /app /var/secrets

# Копируем установленные пакеты и их executables
COPY --from=dependencies /usr/local/lib/python3.11/site-packages \
     /usr/local/lib/python3.11/site-packages
COPY --from=dependencies /usr/local/bin/gunicorn \
     /usr/local/bin/gunicorn

# Копируем код приложения
COPY --chown=appuser:appuser app/ /app/

# Переключаемся на non-root
USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD curl -f http://localhost:5000/health || exit 1

EXPOSE 5000

# Используем gunicorn (production-ready)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "main:app"]
