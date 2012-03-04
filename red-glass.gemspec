Gem::Specification.new do |s|
  s.name        = 'red-glass'
  s.version     = '0.0.1'
  s.date        = '2012-02-25'
  s.summary     = "Red Glass"
  s.description = "Selenium event pane."
  s.authors     = ["Frank O'Hara"]
  s.email       = 'frankj.ohara@gmail.com'
  s.files       = Dir.glob("{lib}/**/*")
  s.homepage    = 'http://rubygems.org/gems/red-glass'
  s.add_dependency 'sinatra'
  s.add_dependency 'em-websocket'
  s.add_dependency 'thin'
  s.add_dependency 'selenium-webdriver'
  s.add_dependency 'json'
  s.add_dependency 'uuid'
  s.add_development_dependency 'rack-test'
end
