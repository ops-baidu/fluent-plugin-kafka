# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["kiyoto"]
  gem.email         = ["me@ktamura.com"]
  gem.description   = %q{Fluentd plugin for Apache Kafka}
  gem.summary       = %q{Fluentd plugin for Apache Kafka}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-kafka"
  gem.require_paths = ["lib"]
  gem.version = '0.0.1'
  gem.add_dependency 'fluentd'
  gem.add_dependency 'kafka-rb'
  gem.add_dependency 'rest-client'
end
