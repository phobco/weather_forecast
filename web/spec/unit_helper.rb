require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require_relative '../config/environment'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/testing/time_helpers'

require_relative '../app/services/weather_service'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
