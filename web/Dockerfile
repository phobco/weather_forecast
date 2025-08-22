# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t weather_forecast .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name weather_forecast weather_forecast

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set development environment
ENV RAILS_ENV="development" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT=""

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev node-gyp pkg-config python-is-python3 unzip && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Bun
ARG BUN_VERSION=1.0.35
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash && \
    mkdir -p /usr/local/bun/bin && \
    ln -s /root/.bun/bin/bun /usr/local/bun/bin/bun

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local path '/usr/local/bundle' && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Install dependencies with Bun
COPY package.json ./
RUN bun install

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Build JavaScript assets
RUN bun run build

# Build CSS assets
RUN bundle exec rails tailwindcss:build

# List compiled assets to verify they exist
RUN ls -la app/assets/builds/

# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails
COPY --from=build /usr/local/bun /usr/local/bun

# Make bun available in PATH
ENV PATH=/usr/local/bun/bin:$PATH

# Create necessary directories
RUN mkdir -p /rails/app/assets/builds

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server for development
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
