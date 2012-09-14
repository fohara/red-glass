require 'observer'

module Selenium
  module WebDriver
    class Driver
      include SearchContext
      include Observable

      def found_element(element)
        changed
        notify_observers element
      end

    end # Driver
  end # WebDriver
end # Selenium
