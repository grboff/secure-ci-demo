В данном проекте используется подход с BuildKit Secrets для временного монтирования секрета, таким образом он не попадает в layers 

Что реализовано:

### 1. **Multi-stage Docker Build**
- **Base stage**: минимальный Python 3.11-slim образ с системными зависимостями
- **Dependencies stage**: слой с установленными pip пакетами и оптимизацией через cache mounts
- **Build stage**: демонстрация работы с секретами через `RUN --mount=type=secret`
- **Final stage**: финальный минимальный образ (только необходимое)

**Результат**: снижение размера образа и исключение секретов из layers

### 2. **Secure Secrets Handling**
- Секреты монтируются **временно** (`/run/secrets/github_token`) и НЕ копируются в образ
- GitHub Actions передает `PRIVATE_REPO_TOKEN` через `--secret` флаг
- Демонстрация безопасного использования: не expose токены, не пишем в history


### 3. **Non-root User**
- Приложение работает от пользователя (не от root)
- Минимальные привилегии для выполнения рабочих процессов
- Соответствие best practice для production контейнеров

### 4. **CI/CD Pipeline (GitHub Actions)**
✓ Build with BuildKit secrets
✓ Push to GitHub Container Registry (GHCR)
✓ Trivy security scanning (CRITICAL & HIGH severity)
✓ GitHub Actions cache для ускорения сборок

### 5. **Health Checks & Monitoring**
- HEALTHCHECK в Dockerfile для Kubernetes/Docker Compose
- `/health` endpoint для проверки состояния
- Gunicorn (production-ready) вместо Flask dev server

## Быстрый старт

# Собрать образ
docker build -t secure-ci-demo:local .

# Запустить локально
docker run -d -p 5001:5000 --name secure-demo secure-ci-demo:local

# Проверить endpoints
curl http://localhost:5001/              # основной endpoint
curl http://localhost:5001/health        # health check
curl http://localhost:5001/config        # конфигурация

Упаковано в пакет:

docker pull ghcr.io/grboff/secure-ci-demo:sha-136f8c0

# Запустить приложение
docker run -d -p 5000:5000 ghcr.io/grboff/secure-ci-demo:main
