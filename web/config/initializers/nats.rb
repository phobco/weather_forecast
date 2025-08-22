# frozen_string_literal: true

require 'nats/client'

# Initialize NATS connection based on environment
Rails.application.config.after_initialize do
  nats_config = Rails.application.config.nats

  begin
    Rails.logger.info 'Connecting to NATS...'

    $nats_connection = NATS.connect(nats_config)
    $jetstream = $nats_connection.jetstream

    Rails.logger.info "NATS connection established successfully. Server: #{$nats_connection.connected_server}"
  rescue StandardError => e
    Rails.logger.error "Failed to connect to NATS: #{e.message}"
    $nats_connection = nil
    $jetstream = nil
  end
end

Signal.trap('TERM') do
  if defined?($nats_connection) && $nats_connection
    $nats_connection.close
    Rails.logger.info('NATS connection closed')
  end
end

Signal.trap('INT') do
  if defined?($nats_connection) && $nats_connection
    $nats_connection.close
    Rails.logger.info('NATS connection closed')
  end
end
