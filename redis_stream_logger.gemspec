require_relative 'lib/redis_stream_logger/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_stream_logger"
  spec.version       = RedisStreamLogger::VERSION
  spec.authors       = ["Mike Harris"]
  spec.email         = ["mike.harris@cerner.com"]

  spec.summary       = "Provides a log device to send logs to a Redis stream"
  spec.homepage      = "https://github.com/mlh758/redis_stream_logger"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'redis', '~> 4.0'
end
