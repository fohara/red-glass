require "selenium-webdriver"
require "uuid"

class RedGlass
  attr_accessor :driver, :test_id

  def initialize(driver)
    @driver = driver
  end

  def start
    uuid = UUID.new
    @test_id = uuid.generate
    #if !has_jQuery?
      load_jQuery
    #end
    load_json2
    load_get_path
    load_red_glass_js
  end

  def stop

  end

  private

  def has_jQuery?
    @driver.execute_script "var hasJQuery = typeof jQuery == 'function' ? true : false; return hasJQuery"
  end

  def load_jQuery
    raw_js = File.open(File.expand_path('../red-glass/public/scripts/jquery-1.7.1.js'), 'rb').read
    @driver.execute_script raw_js
  end

  def load_json2
    has_old_json = @driver.execute_script "var hasOldJSON = typeof JSON.license == 'undefined' ? false : true; return hasOldJSON"
    if has_old_json
      @driver.execute_script "delete JSON"
    end
    raw_js = File.open(File.expand_path('../red-glass/public/scripts/json2.js'), 'rb').read
    @driver.execute_script raw_js
  end

   def load_get_path
    raw_js = File.open(File.expand_path('../red-glass/public/scripts/jquery.getpath.js'), 'rb').read
    @driver.execute_script raw_js
  end

  def load_red_glass_js
    raw_js = File.open(File.expand_path('../red-glass/public/scripts/jquery.red-glass-0.1.0.js'), 'rb').read
    @driver.execute_script raw_js
    @driver.execute_script("jQuery(document).redGlass('#{@test_id}')")
    @driver.execute_script "jQuery.noConflict(true)"
  end

end