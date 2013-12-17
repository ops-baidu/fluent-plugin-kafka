class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'kafka'
  end

  config_param :product, :string, :default => nil
  config_param :service, :string, :default => nil

  config_param :host, :string, :default => "buffer.aqueducts.baidu.com"
  config_param :port, :integer, :default => 2181

  def configure(conf)
    super
    @producers = {} # keyed by topic:partition

####################################
    @default_topic = "#{@product}_#{@service}_topic"
    @default_partition = 0

    unless @host and @port
      $log.error "==========================================================="
      $log.error "|| host and port must be given."
      $log.error "==========================================================="
      exit 1
    end

    require 'socket'
    @host_local = Socket.gethostname
    @ip_local = Socket::getaddrinfo(@host_local, Socket::SOCK_STREAM)[0][3]
    @idc = @host_local.split("-")[0]

    unless check(@product, @service)
      $log.error "==========================================================="
      $log.error "|| please sign up frist. http://aqueduct.baidu.com"
      $log.error "==========================================================="
      exit 1
    else
      $log.info "==========================================================="
      $log.info "|| product = #{@product}"
      $log.info "|| service = #{@service}"
      $log.info "|| topic = #{@default_topic}"
      $log.info "|| partition = #{@default_partition}"
      $log.info "==========================================================="
    end

######################################
  end

  def check(product, service)
    require 'rest-client'
#    response = RestClient.get 'http://aqueducts.baidu.com.com/validation/', {:params => {:product => product, 'service' => service}}

    return true;
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
      topic = record['topic'] || @default_topic || tag
      partition = record['partition'] || @default_partition

      record["hostname"] = @host_local
      record["localip"] = @ip_local
      record["idc"] = @idc

      require 'json'
      message = Kafka::Message.new(record.to_json)
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
          :port      => @port,
          :host      => @host,
          :topic     => topic,
          :partition => partition
        }
        @producers[topic] ||= Kafka::ZKProducer.new(config)
        @producers[topic].push(messages)
      }
    }
  end
end
