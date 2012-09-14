module Selenium
  module WebDriver
    module SearchContext

      def find_element(*args)
        how, what = extract_args(args)

        unless by = FINDERS[how.to_sym]
          raise ArgumentError, "cannot find element by #{how.inspect}"
        end

        result = bridge.find_element_by by, what.to_s, ref
        self.found_element result
        result
      end

      def find_elements(*args)
        how, what = extract_args(args)

        unless by = FINDERS[how.to_sym]
          raise ArgumentError, "cannot find elements by #{how.inspect}"
        end

        bridge.find_elements_by by, what.to_s, ref
      end

    end # SearchContext
  end # WebDriver
end # Selenium
