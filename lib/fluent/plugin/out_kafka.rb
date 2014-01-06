class Array
  def has_service(service)
    self.select { |el| el["name"] == "#{service}" } != []
  end
end
class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'poseidon'
    require 'json'
  end

  config_param :product, :string, :default => nil
  config_param :service, :string, :default => nil

  config_param :host, :string, :default => "buffer.aqueducts.baidu.com"
  config_param :port, :integer, :default => 2181

  config_param :apidomain, :string, :default => "api.aqueducts.baidu.com"
  config_param :skip_check, :string, :default => "false"

  def configure(conf)
    super
####################################
    @default_topic = "#{@product}_#{@service}_topic"

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
      $log.info "==========================================================="
    end

######################################
  end

  def check(product, service)
    require 'rest-client'

    response = RestClient.get "http://#{@apidomain}:/v1/products/#{product}/services"
    @services = JSON.parse(response)
    return true if @services.has_service("#{service}")
    return true if @skip_check == "true"
    return false
  end

  def start
    super
    brokers = get_brokers_from_zk(@host, @port)
    @producer = Poseidon::Producer.new(brokers, @host_local)
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
      record["hostname"] = @host_local
      record["localip"] = @ip_local
      record["idc"] = @idc
      record["event_time"] = Time.now.to_f.to_s

      #messages <<  Poseidon::MessageToSend.new(topic, record.to_json, "opt_key")
      messages <<  Poseidon::MessageToSend.new(@default_topic, record.to_json)
    }
    @producer.send_messages(messages)
  end

  def get_brokers_from_zk(zkhost, zkport)
    require 'zookeeper'

    brokers = []
    zk = Zookeeper.new("#{zkhost}:#{zkport}")
    zk.get_children(:path => "/brokers/ids")[:children].each do |ids|
      broker_meta = zk.get(:path => "/brokers/ids/#{ids}")[:data]
      broker_meta_in_json = JSON.parse(brker_meta)
      @brokers << broker_meta_in_json["host"]
    end
    zk.close
    return brokers
  end
end
