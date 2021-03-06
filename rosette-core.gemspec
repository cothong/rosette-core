$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'rosette/core/version'

Gem::Specification.new do |s|
  s.name     = "rosette-core"
  s.version  = ::Rosette::Core::VERSION
  s.authors  = ["Cameron Dutro"]
  s.email    = ["camertron@gmail.com"]
  s.homepage = "http://github.com/camertron"

  s.description = s.summary = "Core classes for the Rosette internationalization platform."

  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true

  s.add_dependency 'progress-reporters', '~> 1.0'
  s.add_dependency 'activesupport', '>= 3.2', '< 5'
  s.add_dependency 'aasm', '~> 4.1'
  s.add_dependency 'concurrent-ruby', '~> 1.0'
  s.requirements << "jar 'org.eclipse.jgit:org.eclipse.jgit', '3.4.1.201406201815-r'"

  s.require_path = 'lib'
  s.files = Dir["{lib,spec}/**/*", "Gemfile", "History.txt", "README.md", "Rakefile", "rosette-core.gemspec"]
end
