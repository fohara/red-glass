require 'observer'

module Selenium
  module WebDriver
    class Navigation
      include Observable

      def to(url)
        result = @bridge.get url
        changed
        notify_observers url
        result
      end

    end
  end
end