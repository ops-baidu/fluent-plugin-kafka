class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'kafka'
  end

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 9092
  config_param :default_topic, :string, :default => nil
  config_param :default_partition, :integer, :default => 0

  def configure(conf)
    super
    @producers = {} # keyed by topic:partition
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
      partition = record['partition'] || self.default_partition
      message = Kafka::Message.new(record.to_s)
      records_by_topic[topic] ||= []
      records_by_topic[topic][partition] ||= []
      records_by_topic[topic][partition] << message
    }
    publish(records_by_topic)
  end

  def publish(records_by_topic)
    records_by_topic.each { |topic, partitions|
      partitions.each_with_index { |messages, partition|
        next if not messages
        config = {
          :port      => self.port,
          :host      => self.host,
          :topic     => topic,
          :partition => partition
        }
        @producers[topic] ||= Kafka::Producer.new(config)
        @producers[topic].send(messages)
      }
    }
  end
end
