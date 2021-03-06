Gem::Specification.new do |s|
  s.required_ruby_version = '>= 1.9.3'
  s.license = "BSD"
  s.name = %q{git_time_extractor}
  s.version = "0.2.3"
  s.authors = ["Frank Rietta"]
  s.email = "products@rietta.com"
  s.summary = "Reasonable developer time log extractor that uses a GIT repository's commit log history."
  s.description = "Compute the estimated time spent by developers working on code within a GIT repository. Useful for verifying developer time sheets and for tax purposes. See https://github.com/rietta/git_time_extractor/wiki."
  s.homepage = "https://github.com/rietta/git_time_extractor"
  s.files = ["bin/git_time_extractor", "README.txt", "History.txt"] + Dir["lib/**/*"]
  s.bindir = "bin"
  s.executables = ["git_time_extractor"]
  s.add_dependency "git", "~>1.2.6"
  s.add_dependency "logger", "~>1.2.8"
end