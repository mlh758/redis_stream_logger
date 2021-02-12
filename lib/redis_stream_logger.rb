require "redis_stream_logger/version"
require "redis_stream_logger/log_device"
require 'redis_stream_logger/railtie' if defined?(Rails::Railtie)

module RedisStreamLogger
  class Error < StandardError; end
  # Your code goes here...
end
