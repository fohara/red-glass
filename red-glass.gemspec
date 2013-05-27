Gem::Specification.new do |s|
  s.name        = 'red-glass'
  s.version     = '0.1.1'
  s.date        = '2013-05-26'
  s.summary     = "Red Glass: Selenium event pane"
  s.description = "Red Glass works alongside Selenium to observe browser events, and provides an interactive log which illustrates changes to the DOM during an automation session."
  s.authors     = ["Frank O'Hara"]
  s.email       = 'frankj.ohara@gmail.com'
  s.files       = Dir.glob("{lib}/**/*")
  s.homepage    = 'https://github.com/fohara/red-glass'
  s.add_dependency 'sinatra'
  s.add_dependency 'em-websocket'
  s.add_dependency 'thin'
  s.add_dependency 'selenium-webdriver', '>= 2.32.0'
  s.add_dependency 'json'
  s.add_dependency 'uuid'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'rspec'
end
