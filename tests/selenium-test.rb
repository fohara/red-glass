require "selenium-webdriver"
require_relative '../red_glass'

driver = Selenium::WebDriver.for :firefox
red_glass = RedGlass.new driver

driver.get "http://rubular.com/"

red_glass.start

wait = Selenium::WebDriver::Wait.new(:timeout => 10)

driver.find_element(:id, 'regex').send_keys 'blah'
driver.find_element(:id, 'test').send_keys 'blah'
driver.find_element(:link_text, 'clear fields').click

red_glass.stop

driver.quit