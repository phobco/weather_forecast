FROM ruby:3.4-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    cron && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x bin/start init.sh

RUN echo '0 * * * * cd /app && ./bin/start ${WEATHER_CONFIG_PATH:-} >> /proc/1/fd/1 2>&1' > /etc/cron.d/weather-cron && \
    chmod 0644 /etc/cron.d/weather-cron

CMD ["/app/init.sh"]
