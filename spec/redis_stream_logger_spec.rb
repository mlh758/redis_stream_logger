RSpec.describe RedisStreamLogger do
  let(:client_mock) { double('client', connect: nil) }
  let(:redis_mock) { double('redis', sadd: nil, close: nil, xadd: nil, _client: client_mock) }
  before do
    allow(redis_mock).to receive(:pipelined) do |_, &block|
      block.call()
    end
  end
  it 'prioritizes config in block over initializer parameters' do
    device = RedisStreamLogger::LogDevice.new(stream: 'other') do |conf|
      conf.connection = redis_mock
      conf.stream_name = 'should-be-this'
    end
    expect(device.config.stream_name).to eq 'should-be-this'
    device.close # close after specs to ensure errors from threads are raised
    expect(redis_mock).to have_received(:sadd).with('log-streams', 'should-be-this')
  end

  it 'sends logs to during close process even if buffer is not full' do
    device = RedisStreamLogger::LogDevice.new(stream: 'other') do |conf|
      conf.connection = redis_mock
      conf.buffer_size = 10
    end
    (1..11).each { |i| device.write('hello') }
    device.close
    expect(redis_mock).to have_received(:xadd).exactly(11).times
  end

  it 'sends a partial buffer after the ticker wakes up the writer thread' do
    device = RedisStreamLogger::LogDevice.new(stream: 'other') do |conf|
      conf.connection = redis_mock
      conf.buffer_size = 100
      conf.send_interval = 0.5
    end
    (1..5).each { |i| device.write('hello') }
    sleep(1)
    expect(redis_mock).to have_received(:xadd).exactly(5).times
    device.close
  end

  it 'reconnects when given the reopen command after flushing and resumes listening' do
    device = RedisStreamLogger::LogDevice.new(stream: 'other') do |conf|
      conf.connection = redis_mock
      conf.buffer_size = 10
    end
    device.write('hello')
    device.reopen
    expect(redis_mock).to have_received(:xadd).with('other', m: 'hello')
    device.write('hello again')
    device.close
    expect(redis_mock).to have_received(:xadd).with('other', m: 'hello again')
  end
end
