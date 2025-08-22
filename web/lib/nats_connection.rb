# frozen_string_literal: true

module NatsConnection
  def self.client
    $nats_connection
  end

  def self.jetstream
    $jetstream
  end

  def self.connected?
    client && client.status == 1
  end

  def self.jetstream_available?
    return false unless client
    return false unless connected?
    return false unless jetstream

    true
  end
end
