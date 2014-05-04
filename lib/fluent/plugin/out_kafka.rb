class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'poseidon'
    require 'json'
  end

  config_param :host, :string, :default => "buffer.aqueducts.baidu.com"
  config_param :port, :integer, :default => 2181

  def configure(conf)
    super
####################################

    unless @host and @port
      $log.error "==========================================================="
      $log.error "|| host and port must be given."
      $log.error "==========================================================="
      exit 1
    end

    require 'socket'
    @host_local = Socket.gethostname
    @ip_local = Socket::getaddrinfo(@host_local, Socket::SOCK_STREAM)[0][3]
    @idc_local = @host_local.split("-")[0]

######################################
  end

  def start
    super
    brokers = get_brokers_from_zk(@host, @port)
    options = {:type => :async, :required_acks => 0, :max_send_retries => 3}
    @producer = Poseidon::Producer.new(brokers, @host_local, options)
  end

  def shutdown
    @producer = nil
    super
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def write(chunk)
    messages = []
    chunk.msgpack_each { |tag, time, record|

      topic_name = "#{record["product"]}_#{record["service"]}_topic"

      record["collector_host"] = @host_local
      record["collector_idc"] = @idc_local
      record["collector_ip"] = @ip_local
      record["collector_time"] = (Time.now.to_f * 1000).to_i

      #messages <<  Poseidon::MessageToSend.new(topic, record.to_json, "opt_key")
      messages <<  Poseidon::MessageToSend.new(topic_name, record.to_json)
    }
    @producer.send_messages(messages)
  end

  def get_brokers_from_zk(zkhost, zkport)
    require 'zookeeper'

    brokers = []
    zk = Zookeeper.new("#{zkhost}:#{zkport}")
    zk.get_children(:path => "/brokers/ids")[:children].each do |ids|
      broker_meta = zk.get(:path => "/brokers/ids/#{ids}")[:data]
      broker_meta_in_json = JSON.parse(broker_meta)
      brokers << broker_meta_in_json["host"] + ":" + broker_meta_in_json["port"].to_s
    end
    zk.close
    return brokers
  end
end
