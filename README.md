# Weather Forecast

## Быстрый старт

### 1. Настройка переменных окружения
Создаём `.env` файл
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

\* в случае ошибки выполнить следующую команду в новой вкладке терминала:
```bash
docker exec weather_forecast-web-1 bin/rails assets:precompile
```

## Структура проекта
- `weather_fetcher/` - Ruby сервис для получения погоды
- `web/` - Rails приложение для отображения погоды
- `nats.conf` - конфигурация NATS сервера





