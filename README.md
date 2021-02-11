# RedisStreamLogger

This gem creates a [log device](https://github.com/ruby/logger/blob/bf6d5aa37ee954afc49a407e67fb96064a52af62/lib/logger/log_device.rb) to send your logs to a Redis stream.

The log device will buffer requests internally until either a time interval or buffer size is hit and then it will send all the log entries as a pipeline to minimize network
traffic.

There is a basic viewer for this logger (or any Redis stream if you're feeling brave) [here](https://github.com/mlh758/stream_log_viewer). It supports tailing
a stream or searching logs with basic text matching.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_stream_logger'
```

## Usage

To use in an application add something like this:

```rb
redis_log = RedisStreamLogger::LogDevice.new do |config|
  config.connection = Redis.new
end
logger = Logger.new(redis_log)
```

It is _highly_ recommended that you set timeouts on your Redis connection. See the [Redis docs](https://github.com/redis/redis-rb/#timeouts).

If you are using a forking Rails server like Passenger this gets a lot weirder because currently the logger uses threads
to handle IO and avoid blocking the main app. For Rails and Passenger it will look something like this:

```rb
# config.ru
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    next unless forked
    Rails.logger.close
    redis_log = RedisStreamLogger::LogDevice.new do |config|
      config.connection = Redis.new
      config.stream_name = 'app-logs'
    end
    logger = Logger.new(redis_log)
    logger.level = Rails.application.config.log_level
    Rails.logger = logger
    Rails.application.config.logger = logger
    Rails.application.config.action_controller.logger = logger
  end
end
```

I'm currently looking for a way to use one of the async libraries to improve things.

### Configuration

* buffer_size: Max number of items to hold in queue before attempting to write a batch. Defaults to 100
* send_interval: Number of seconds to wait before sending the buffer, despite buffer_size. Defaults to 10
* connection: Redis connection to use for logger
* batch_size: Number of of log items to send to Redis at a time. Defaults to buffer_size
* stream_name: Stream to publish messages to
* max_len: Maximum size of stream. Ideally you will have a log consumer set up that calls xtrim after persisting your logs somewhere.
  If that's more than you need, and just want a simple way to cap the log size set max_len to some sufficiently large number to keep your logs around long enough to be useful.
* log_set_key: Loggers will store the name of their stream into this key for discoverability

## Path to 1.0

The use of threads caused unexpected headaches in applications that rely on forking like Passenger. I'm hoping this library can drop the reliance on threads.

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rake spec` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/mlh758/redis_stream_logger).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
