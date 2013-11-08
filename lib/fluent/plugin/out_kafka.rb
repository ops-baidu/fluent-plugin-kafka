class Fluent::KafkaOutput < Fluent::BufferedOutput
  Fluent::Plugin.register_output('kafka', self)

  def initialize
    super
    require 'kafka'

#extra info feature,added by liyong
    require 'socket'
    @host_local = Socket.gethostname
    @ip_local = Socket::getaddrinfo(@host_local, Socket::SOCK_STREAM)[0][3]
    @idc = @host_local.split("-")[0]
####################################

  end

  config_param :host, :string, :default => 'localhost'
  config_param :port, :integer, :default => 9092
  config_param :zkhost, :string, :default => nil
  config_param :zkport, :integer, :default => nil
  config_param :default_topic, :string, :default => nil
  config_param :default_partition, :integer, :default => 0
  config_param :need_platform_info, :bool, :default => false

  def configure(conf)
    super
    @producers = {} # keyed by topic:partition
#####################################
    if @need_platform_info
      @platform = "Aqueducts"
=begin require 'nodes'
      im_nodes = Nodes.new()
      result = im_nodes.search_tags(@host_local.split(".baidu.com")[0])
      if result["status"] != 0
        @platform = ""
      else
        mid_array = result["data"]["tags"]
        platform_list = mid_array.select{|x| x[0] == "PLATFORM"}
        platform_list.each do |y|
          @platform = /[A-Za-z]+[0-9]+/.match(y[1]).to_s
          break if @platform != ''
        end
      end
=end
    end
######################################
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
#extra info feature,added by liyong
      record["hostname"] = @host_local
      record["localip"] = @ip_local
      record["idc"] = @idc
      record["platform"] = @platform  if @need_platform_info
###################################
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
        if @zkhost and @zkport
          config = {
            :port      => @zkport,
            :host      => @zkhost,
            :topic     => topic,
            :partition => partition
          }
          @producers[topic] ||= Kafka::ZKProducer.new(config)
          @producers[topic].zkpush(messages)
        elsif @host and @port
          config = {
            :port      => @port,
            :host      => @host,
            :topic     => topic,
            :partition => partition
          }
          @producers[topic] ||= Kafka::Producer.new(config)
          @producers[topic].push(messages)
        else
          puts "host or port argument is nil"
        end
      }
    }
  end
end
