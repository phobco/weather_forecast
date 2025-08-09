#!/bin/sh

echo "Starting cron daemon..."
crond -l 2 -f &

echo "Running initial weather fetch..."
cd /app && ./bin/start

echo "Initial fetch complete. Cron will run every hour."

wait
