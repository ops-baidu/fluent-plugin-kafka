module Fluent

class KafkaInput < Input
  Plugin.register_input('kafka', self)

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 9092
  config_param :interval, :integer, :default => 1 # seconds
  config_param :topics, :string

  def initialize
    super
    require 'kafka'
  end

  def configure(conf)
    super
    @topic_list = @topics.split(',').map {|topic| topic.strip }
    if @topic_list.empty?
      raise ConfigError, "kafka: 'topics' is a require parameter"
    end
  end

  def start
    @loop = Coolio::Loop.new
    @topic_watchers = @topic_list.map {|topic|
      TopicWatcher.new(topic, @host, @port, interval)
    }
    @topic_watchers.each {|tw|
      tw.attach(@loop)
    }
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    @loop.stop
  end

  def run
    @loop.run
  rescue
    $log.error "unexpected error", :error=>$!.to_s
    $log.error_backtrace
  end

  class TopicWatcher < Coolio::TimerWatcher
    def initialize(topic, host, port, interval)
      @topic = topic
      @callback = method(:consume)
      @consumer = Kafka::Consumer.new({
        :topic => topic,
        :host => host,
        :port => port
      })
      super(interval, true)
    end

    def on_timer
      @callback.call
    rescue
        # TODO log?
        $log.error $!.to_s
        $log.error_backtrace
    end

    def consume
      es = MultiEventStream.new
      @consumer.consume.each { |msg|
        begin
          # TODO: ask upstream for conversion
          # i.e., it should be msg.to_hash or something
          msg_record = {
            :magic => msg.magic,
            :checksum => msg.checksum,
            :payload => msg.payload
          }
          $log.info msg_record.to_s
          es.add(Time.now.to_i, msg_record)
        rescue
          $log.warn msg_record.to_s, :error=>$!.to_s
          $log.debug_backtrace
        end
      }

      unless es.empty?
        Engine.emit_stream(@topic, es)
      end
    end
  end
end

end
