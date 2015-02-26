# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudfinder-ec2/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudfinder-ec2"
  gem.version       = Cloudfinder::EC2::VERSION
  gem.authors       = ["Andrew Coulton"]
  gem.email         = ["andrew@ingenerator.com"]
  gem.license       = 'BSD-3-Clause'
  gem.description   = 'Uses EC2 instance tags to locate all the running instances in a given cluster, grouped by role.'
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/edbookfest/cloudfinder-ec2"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'aws-sdk', '~>2.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'guard'
  gem.add_development_dependency 'guard-rspec'
end
