Gem::Specification.new do |s|
  s.name = "cbor-cri"
  s.version = "0.0.4"
  s.summary = "CBOR (Concise Binary Object Representation) diagnostic notation"
  s.description = %q{cbor-cri implements CBOR constrained resource identifiers, draft-ietf-core-href}
  s.author = "Carsten Bormann"
  s.email = "cabo@tzi.org"
  s.license = "MIT"
  s.homepage = "http://cbor.io/"
  # s.files = `git ls-files`.split("\n") << "lib/cbor-diag-parser.rb"
  # s.test_files = `git ls-files -- {test,spec}/*`.split("\n")
  s.files = Dir['lib/**/*.rb'] + %w(cbor-cri.gemspec) + Dir['bin/**/*.rb']
  s.executables = Dir['bin/**/*.rb'].map {|x| File.basename(x)}
  s.required_ruby_version = '>= 2.3'

  s.require_paths = ["lib"]

  s.add_development_dependency 'bundler', '~>1'
end
