## branch for astream collector

- depend on customize (out_forward.rb)[https://gist.github.com/castomer/9043610]


## add zookeeper support

- push logs to kafka through zookeeper.
- using poseidon
- jiuze#baidu.com

## config example

    <match kafka.*.*>
      # plugin type (requried)
      type kafka
    
      # product & service (requried)
      product aqueducts
      service astream
    
      # buffer config (only requried in development mode, defalut value is ok for production.)
      host 192.168.1.20
      port 2181
    
      # interval (optional, but it may affect the latency.)
      flush_interval 1s
    </match>


# Fluent::Plugin::Kafka

TODO: Write a gem description
TODO: Also, I need to write tests

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-kafka'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-kafka

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
