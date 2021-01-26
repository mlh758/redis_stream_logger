# RedisStreamLogger

This gem creates a [log device](https://github.com/ruby/logger/blob/bf6d5aa37ee954afc49a407e67fb96064a52af62/lib/logger/log_device.rb) to send your logs to a Redis stream.

The log device will buffer requests internally until either a time interval or buffer size is hit and then it will send all the log entries as a pipeline to minimize network
traffic.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_stream_logger'
```

## Usage

To use in a Rails application add something like this to your config:

```rb
redis_log = RedisStreamLogger::LogDevice.new do |config|
  config.connection = Redis.new
end
config.logger = Logger.new(redis_log)
```

It is _highly_ recommended that you set timeouts on your Redis connection. See the [Redis docs](https://github.com/redis/redis-rb/#timeouts).

### Configuration

* buffer_size: Max number of items to hold in queue before attempting to write a batch. Defaults to 100
* send_interval: Number of seconds to wait before sending the buffer, despite buffer_size. Defaults to 10
* connection: Redis connection to use for logger
* batch_size: Number of of log items to send to Redis at a time. Defaults to buffer_size
* stream_name: Stream to publish messages to
* max_len: Maximum size of stream. Ideally you will have a log consumer set up that calls xtrim after persisting your logs somewhere.
  If that's more than you need, and just want a simple way to cap the log size set max_len to some sufficiently large number to keep your logs around long enough to be useful.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mlh758/redis_stream_logger.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
