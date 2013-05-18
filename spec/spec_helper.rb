require 'rspec'
require 'selenium-webdriver'
require 'json'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end