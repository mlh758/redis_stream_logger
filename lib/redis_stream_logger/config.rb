module RedisStreamLogger
  #
  # Config provides configuration options for the log device.
  # buffer_size: Max number of items to hold in queue before attempting to write a batch
  # defaults to 100
  # send_interval: Number of seconds to wait before sending the buffer, despite buffer_size
  # defaults to 10
  # connection: Redis connection to use for logger
  # batch_size: Number of of log items to send to Redis at a time
  # defaults to buffer_size
  # stream_name: Stream to publish messages to
  # max_len: Maximum size of stream. Ideally you will have a log
  # consumer set up that calls xtrim after persisting your logs somewhere.
  # If that's more than you need, and just want a simple way to cap the log size
  # set max_len to some sufficiently large number to keep your logs around long
  # enough to be useful.
  #
  class Config
    attr_accessor :buffer_size, :send_interval, :connection, :batch_size, :stream_name, :max_len, :log_set_key

    def initialize
      @buffer_size = 100
      @send_interval = 10
      @connection = nil
      @batch_size = @buffer_size
      @stream_name = nil
      @max_len = nil
      @log_set_key = "log-streams"
    end
  end
end