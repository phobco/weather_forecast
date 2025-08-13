require 'cucumber/rails'
require 'nats/client'
require 'json'

# Capybara configuration for Docker environment
Capybara.default_driver = :rack_test  # Use rack_test instead of selenium
Capybara.javascript_driver = :rack_test
Capybara.run_server = false  # Don't start a server, use the one already running
Capybara.app_host = 'http://localhost:3000'  # Point to the Docker container
Capybara.default_max_wait_time = 10

# NATS configuration for tests
NATS_TEST_URL = ENV.fetch('NATS_TEST_URL', 'nats://test_user:test_password@localhost:4222')
NATS_STREAM_NAME = 'WEATHER_STREAM'

Before do
  # Override NATS_URL for WeatherService to use test credentials
  ENV['NATS_URL'] = NATS_TEST_URL
  setup_nats_test_data
end

After do
  cleanup_nats_test_data
end

# Disable database transactions for Cucumber
Cucumber::Rails::World.use_transactional_tests = false

private

def setup_nats_test_data
  begin
    @nats_client = NATS.connect(NATS_TEST_URL, timeout: 5)
    @jetstream = @nats_client.jetstream

    # Create stream if it doesn't exist
    begin
      @jetstream.stream_info(NATS_STREAM_NAME)
      puts "Stream #{NATS_STREAM_NAME} already exists"
    rescue NATS::JetStream::Error::NotFound
      @jetstream.add_stream(
        name: NATS_STREAM_NAME,
        subjects: [ 'weather.*' ]
      )
      puts "Created stream #{NATS_STREAM_NAME}"
    end

    publish_test_weather_data
    puts "NATS setup completed successfully"
  rescue => e
    puts "NATS setup failed: #{e.message}"
    raise e
  end
end

def cleanup_nats_test_data
  @nats_client&.close
  @nats_client = nil
  @jetstream = nil
end

def publish_test_weather_data
  test_data = {
    'moscow' => {
      'city' => 'Moscow',
      'date' => Time.current.strftime('%Y-%m-%d'),
      'hourly_forecast' => [
        {
          'hour' => 12,
          'display_time' => '12:00',
          'temperature' => 22.5
        },
        {
          'hour' => 13,
          'display_time' => '13:00',
          'temperature' => 24.1
        },
        {
          'hour' => 14,
          'display_time' => '14:00',
          'temperature' => 25.8
        }
      ]
    },
    'saint_petersburg' => {
      'city' => 'Saint Petersburg',
      'date' => Time.current.strftime('%Y-%m-%d'),
      'hourly_forecast' => [
        {
          'hour' => 12,
          'display_time' => '12:00',
          'temperature' => 18.2
        },
        {
          'hour' => 13,
          'display_time' => '13:00',
          'temperature' => 19.5
        },
        {
          'hour' => 14,
          'display_time' => '14:00',
          'temperature' => 20.1
        }
      ]
    }
  }

  test_data.each do |city, data|
    subject = "weather.#{city}"
    @jetstream.publish(subject, data.to_json)
    puts "Published data for #{city}: #{data.to_json}"
  end
end
