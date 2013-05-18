require 'selenium/webdriver/support/abstract_event_listener'

class RedGlassListener < Selenium::WebDriver::Support::AbstractEventListener
  attr_accessor :red_glass

  def after_navigate_back(driver)
    @red_glass.reload
  end

  def after_navigate_forward(driver)
    @red_glass.reload
  end

  def after_navigate_to(url, driver)
    @red_glass.reload
  end

end