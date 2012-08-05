class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'kafka'
  end

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 9092
  config_param :default_topic, :string, :default => nil

  def configure(conf)
    super
    @producers = {} # keyed by partition:topic
    @kafka_config = {
      :port => self.port,
      :host => self.host
    }
  end

  def start
    super
  end

  def shutdown
    super
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    records_by_topic = {}
    chunk.msgpack_each { |tag, time, record|
      topic = record['topic'] || self.default_topic || tag
      message = Kafka::Message.new(record.to_s)
      records_by_topic[topic] ||= []
      records_by_topic[topic] << message
    }
    publish(records_by_topic)
  end

  def publish(records_by_topic)
    records_by_topic.each { |topic, messages|
      producer = @producers[topic] || Kafka::Producer.new(@kafka_config) 
      producer.send(messages)
    }
  end
end
