FROM ruby:3.4-alpine

RUN apk add --no-cache \
    build-base \
    curl \
    dcron

WORKDIR /app

COPY Gemfile ./

RUN bundle install

COPY . .

RUN chmod +x bin/start

RUN echo "0 * * * * cd /app && ./bin/start >> /proc/1/fd/1 2>&1" > /etc/crontabs/root

CMD ["/app/init.sh"]
