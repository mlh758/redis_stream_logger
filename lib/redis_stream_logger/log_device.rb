require 'logger'
require "redis_stream_logger/config"
module RedisStreamLogger
  class LogDevice
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

      def ticker(interval)
          loop do
              sleep(interval)
              @q.push(:nudge)
          end
      end

      def control_msg?(msg)
          msg == :nudge || msg == :exit
      end

      def writer(buffer_max, interval)
          last_sent = Time.now
          buffered = []
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