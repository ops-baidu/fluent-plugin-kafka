require 'helper'

class KafkaOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
    default_topic aoiyu
    port 1337
    host localhost
  ]

  def create_driver(conf = CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::KafkaOutput, tag).configure(conf)
  end

  def test_configure
    d = create_driver
    assert_equal 'aoiyu', d.instance.default_topic
    assert_equal 1337, d.instance.port
    assert_equal 'localhost', d.instance.host
  end

  def test_format
    d = create_driver
  end

  def test_write
    d = create_driver
    time = Time.parse("2011-01-02 13:14:15 UTC").to_i
    d.emit({"a"=>1}, time)
    d.emit({"a"=>2}, time)
  end
end
