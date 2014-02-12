# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["kiyoto", "dongfang qu"]
  gem.email         = ["me@ktamura.com"]
  gem.description   = %q{Fluentd plugin for Apache Kafka}
  gem.summary       = %q{Fluentd plugin for Apache Kafka 0.8}
  gem.homepage      = "https://github.com/ops-baidu/fluent-plugin-kafka"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-kafka"
  gem.require_paths = ["lib"]
  gem.version = '0.0.2'
  gem.add_dependency 'fluentd'
  gem.add_dependency 'poseidon'
  gem.add_dependency 'rest-client'
end
