require 'logger'
require "redis_stream_logger/config"
module RedisStreamLogger
  class LogDevice

      #
      # Creates a new LogDevice that can be used as a sink for Ruby Logger
      #
      # @param [Redis] conn connection to Redis
      # @param [String] stream name of key to write to
      #
      def initialize(conn = nil, stream: 'rails-log')
          @config = Config.new
          @closed = false
          yield @config if block_given?
          @config.connection ||= conn
          @config.stream_name ||= stream
          raise ArgumentError, 'must provide connection' if @config.connection.nil?

          @q = Queue.new
          @error_logger = ::Logger.new(STDERR)
          @ticker = Thread.new do
              ticker(@config.send_interval)
          end
          @writer = Thread.new do
              writer(@config.buffer_size, @config.send_interval)
          end
          at_exit { close }
      end

      def write(msg)
          @q.push msg
      end

      def reopen(log = nil)
          # no op
      end

      def close
          return if @closed
          @q.push :exit
          @ticker.exit
          @writer.join
          @config.connection.close
          @closed = true
      end

      private

      def send_options
        return {} if @config.max_len.nil?

        { maxlen: @config.max_len, approximate: true }
      end

      #
      # Writes a batch of log lines to the Redis stream
      #
      # @param [Array<String>] messages to write to the stream
      #
      #
      def write_batch(messages)
        redis = @config.connection
        opt = send_options
        messages.each_slice(@config.batch_size) do
          attempt = 0
          begin
            redis.pipelined do
              messages.each do |msg|
                redis.xadd(@config.stream_name, {m: msg}, **opt)
              end
            end
          rescue StandardError => exception
            attempt += 1
            retry if attempt <= 3
            @error_logger.warn "unable to write redis logs: #{exception}"
            messages.each { |m| @error_logger.info(m) }
          end
        end
      end

      #
      # Pushes a message into the queue at the given interval
      # to wake the writer thread up to ensure it sends partial
      # buffers if no new logs come in.
      #
      # @param [Integer] interval to wake the writer up on
      #
      def ticker(interval)
          loop do
              sleep(interval)
              @q.push(:nudge)
          end
      end

      def control_msg?(msg)
          msg == :nudge || msg == :exit
      end

      #
      # Stores the name of the logger in the configured set so other tools can 
      # locate the list of available log streams
      #
      #
      def store_logger_name
        @config.connection.sadd(@config.log_set_key, @config.stream_name)
      rescue StandardError => exception
        @error_logger.warn "unable to store name of log: #{exception}"
      end

      #
      # Used in a thread to pull log messages from a queue and store them in batches into a redis
      # stream.
      #
      # @param [Integer] buffer_max maximum number of log entries to buffer before sending
      # @param [Integer] interval maximum amount of time to wait before sending a partial buffer
      #
      #
      def writer(buffer_max, interval)
          last_sent = Time.now
          buffered = []
          store_logger_name
          loop do
              msg = @q.pop
              buffered.push(msg) unless control_msg?(msg)
              now = Time.new
              if buffered.count >= buffer_max || (now - last_sent) > interval || msg == :exit
                  write_batch(buffered)
                  return if msg == :exit
                  last_sent = Time.now
                  buffered = []
              end
          end
      end
  end
end