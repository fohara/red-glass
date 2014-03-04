require 'selenium/webdriver/support/abstract_event_listener'

class RedGlassListener < Selenium::WebDriver::Support::AbstractEventListener
  attr_accessor :red_glass

  def before_change_value_of(element, driver)
    @red_glass.event_sequence << { :change_value => element.tag_name } if recording?
  end

  def before_click(element, driver)
    @red_glass.event_sequence << { :click => element.tag_name } if recording?
  end

  def after_navigate_back(driver)
    if recording?
      @red_glass.event_sequence.clear
      @red_glass.page_metadata = {}
      @red_glass.reload
    end
  end

  def after_navigate_forward(driver)
    if recording?
      @red_glass.event_sequence.clear
      @red_glass.page_metadata = {}
      @red_glass.reload
    end
  end

  def after_navigate_to(url, driver)
    if recording?
      @red_glass.event_sequence.clear
      @red_glass.page_metadata = {}
      @red_glass.reload
    end
  end

  private

  def recording?
    @red_glass && @red_glass.recording
  end
end