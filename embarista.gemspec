require File.expand_path('../lib/embarista/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Luke Melia", "Kris Selden"]
  gem.email         = ["tech@yapp.us"]
  gem.description   = %q{A collection of web filters for rake-pipeline}
  gem.summary       = %q{A collection of web filters for rake-pipeline used to build Yapp Ember.js apps}
  gem.homepage      = "http://github.com/yappbox/embarista"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "embarista"
  gem.require_paths = ["lib"]
  gem.version       = Embarista::VERSION

  gem.add_dependency "rake-pipeline", '> 0.6.0'
  gem.add_dependency "rake-pipeline-web-filters", '>= 0.6.0'
  gem.add_dependency "execjs"
  gem.add_dependency "ruby_gntp"
  gem.add_dependency "colored"
  gem.add_dependency "aws-sdk"
  gem.add_dependency "zopfli"
  gem.add_dependency "mime-types"

  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rb-readline"
end
