#!/bin/bash

echo "Starting weather fetcher service..."

# Start cron daemon
echo "Starting cron daemon..."
service cron start

# Run initial weather fetch
echo "Running initial weather fetch..."
echo "Config path: ${WEATHER_CONFIG_PATH:-config/weather_config.yml}"

cd /app && ./bin/start ${WEATHER_CONFIG_PATH:-}

echo "Initial fetch complete. Cron will run every hour."
echo "Logs: tail -f /var/log/cron.log"

# Keep container running
tail -f /dev/null
