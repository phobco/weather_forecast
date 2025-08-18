# Weather Forecast

## Быстрый старт

### 1. Настройка переменных окружения
Создаём `.env` файл
```bash
cp .env.example .env
```

**Важно:** Для доступа к Weather API необходимо будет указать `WEATHER_API_KEY` в `.env` файле. (API ключ будет отправлен вместе со ссылкой на репозиторий)

Пример `.env` файла:
```
NATS_ADMIN_PASSWORD=admin
NATS_FETCHER_PASSWORD=fetcher
NATS_WEB_PASSWORD=web

# https://www.weatherapi.com/my/
WEATHER_API_KEY=<API КЛЮЧ>           <--- заменить <API КЛЮЧ> на реальный ключ

WEATHER_CONFIG_PATH=config/weather_config.yml
```


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

### Дополнительно: проверить работоспособность и данные в NATS
1. Зайти в Rails консоль запущенного Docker контейнера (weather_forecast-web-1)
```bash
docker exec -it weather_forecast-web-1 bundle exec rails c
```
2. Подключиться к NATS клиенту
```ruby
require 'nats/client'
client = NATS.connect('nats://admin:admin@nats:4222')
```

Получение "сырых" данных о погоде в Москве из JetStream
```ruby
raw_data = client.jetstream.get_last_msg('WEATHER_STREAM', 'weather.moscow').data
JSON.parse(raw_data)
```


## Структура проекта
- `weather_fetcher/` - Ruby сервис для получения погоды
- `web/` - Rails приложение для отображения погоды
- `nats.conf` - конфигурация NATS сервера







