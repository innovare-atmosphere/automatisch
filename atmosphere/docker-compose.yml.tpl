version: '3.9'
services:
  main:
    build:
      context: ./docker
      dockerfile: Dockerfile.compose
    entrypoint: /compose-entrypoint.sh
    ports:
      - '3000:3000'
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      - HOST=localhost
      - PROTOCOL=http
      - PORT=3000
      - APP_ENV=production
      - REDIS_HOST=redis
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=${database_name}
      - POSTGRES_USERNAME=${database_user}
      - POSTGRES_PASSWORD=${database_password}
      - ENCRYPTION_KEY=${encription_key}
      - WEBHOOK_SECRET_KEY=${webhook_secret_key}
      - APP_SECRET_KEY=${app_secret_key}
    volumes:
      - automatisch_storage:/automatisch/storage
  worker:
    build:
      context: ./docker
      dockerfile: Dockerfile.compose
    entrypoint: /compose-entrypoint.sh
    depends_on:
      - main
    environment:
      - APP_ENV=production
      - REDIS_HOST=redis
      - POSTGRES_HOST=postgres
      - POSTGRES_DATABASE=${database_name}
      - POSTGRES_USERNAME=${database_user}
      - POSTGRES_PASSWORD=${database_password}
      - ENCRYPTION_KEY=${encription_key}
      - WEBHOOK_SECRET_KEY=${webhook_secret_key}
      - APP_SECRET_KEY=${app_secret_key}
      - WORKER=true
    volumes:
      - automatisch_storage:/automatisch/storage
  postgres:
    image: 'postgres:14.5'
    environment:
      - POSTGRES_DB=${database_name}
      - POSTGRES_USER=${database_user}
      - POSTGRES_PASSWORD=${database_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}']
      interval: 10s
      timeout: 5s
      retries: 5
  redis:
    image: 'redis:7.0.4'
    volumes:
      - redis_data:/data
volumes:
  automatisch_storage:
  postgres_data:
  redis_data: