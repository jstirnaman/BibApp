# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "lisbn"
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Mike Ragalie"]
  s.date = "2015-03-12"
  s.description = "Lisbn (pronounced \"Lisbon\") is a wrapper around String that adds methods for manipulating ISBNs."
  s.email = ["michael.ragalie@verbasoftware.com"]
  s.files = [".gitignore", ".rspec", "Gemfile", "LICENSE", "README.md", "Rakefile", "data/RangeMessage.xml", "lib/lisbn.rb", "lib/lisbn/cache_method.rb", "lib/lisbn/lisbn.rb", "lisbn.gemspec", "spec/cache_method_spec.rb", "spec/lisbn_spec.rb", "spec/spec_helper.rb"]
  s.homepage = "https://github.com/ragalie/lisbn"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Provides methods for converting between ISBN-10 and ISBN-13, checking validity and splitting ISBNs into groups and prefixes"
  s.test_files = ["spec/cache_method_spec.rb", "spec/lisbn_spec.rb", "spec/spec_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<nori>, ["~> 2.0"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<nori>, ["~> 2.0"])
      s.add_dependency(%q<nokogiri>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<nori>, ["~> 2.0"])
    s.add_dependency(%q<nokogiri>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
