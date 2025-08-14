# frozen_string_literal: true

require 'nats/client'

module Nats
  class ConnectionService
    STREAM_NAME = 'WEATHER_STREAM'
    SUBJECTS = ['weather.*'].freeze

    attr_reader :nats_url

    def initialize(nats_url: ENV.fetch('NATS_URL', nil))
      @nats_url = nats_url
      raise 'NATS_URL is not set' if @nats_url.nil? || @nats_url.empty?

      setup_stream
    end

    def client
      @client ||= NATS.connect(@nats_url)
    end

    def jetstream
      @jetstream ||= client.jetstream
    end

    def close
      client&.close
    end

    private

    def setup_stream
      return if stream_exists?

      jetstream.add_stream(
        name: STREAM_NAME,
        subjects: SUBJECTS
      )
    end

    def stream_exists?
      begin
        jetstream.stream_info(STREAM_NAME)
        true
      rescue NATS::JetStream::API::Error => e
        return false if e.message.include?('stream not found')
        raise e
      end
    end
  end
end
