require 'observer'

module Selenium
  module WebDriver
    class Element
      include SearchContext
      include Observable

      def click
        result = bridge.clickElement @id
        changed
        notify_observers
        result
      end

      def found_element(element)
        changed
        notify_observers element
      end

    end
  end
end