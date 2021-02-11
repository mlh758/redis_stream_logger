require 'rails/railtie'

module RedisStreamLogger
  # I based this heavily on the LogstashLogger implementation but we'll only
  # accept our own config class here
  def self.setup(app)
    return unless app.config.redis_stream_logger.present?
    conf = app.config.redis_stream_logger
    raise ArgumentError, 'unexpected config class' unless conf.is_a?(Config)

    logdev = RedisStreamLogger::LogDevice.new do |_c|
      conf
    end

    logger = Logger.new(logdev)
    logger.level = app.config.log_level
    app.config.logger = logger
  end
end

class Railtie < ::Rails::Railtie
  initializer :redis_stream_logger, before: :initialize_logger do |app|
    RedisStreamLogger.setup(app)
  end
end