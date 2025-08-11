# Weather Forecast

## Быстрый старт

### 1. Настройка переменных окружения
```bash
cp .env.example .env
```

**Важно:** Для доступа к Weather API необходим `WEATHER_API_KEY`. (будет отправлен вместе со ссылкой на репозиторий)

### 2. Запуск с Docker
```bash
docker compose up
```

### 3. Открыть приложение
Перейдите в браузере по адресу: http://localhost:3000

## Структура проекта
- `web/` - Rails приложение
- `weather_fetcher/` - Ruby сервис для получения погоды
- `nats.conf` - конфигурация NATS сервера


