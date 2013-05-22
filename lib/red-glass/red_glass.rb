require "selenium-webdriver"
require "uuid"
require "net/http"

class RedGlass
  attr_accessor :driver, :test_id, :opts, :port, :pid, :recording, :event_sequence

  PROJ_ROOT = File.dirname(__FILE__).to_s

  def initialize(driver, opts={})
    @driver = driver
    @opts = opts
    opts[:listener].red_glass = self if opts[:listener]
    @event_sequence = []
    @recording = false
  end

  def start
    set_config
    start_server
    uuid = UUID.new
    @test_id = uuid.generate
    load_js
    @recording = true
  end

  def reload
    set_config
    start_server
    load_js
  end

  def pause
    @recording = false
  end

  def stop
    Process.kill('INT', @pid)
    @recording = false
  end

  private

  def is_server_ready?(time_limit=30)
    is_server_ready = false
    uri = URI.parse("http://localhost:#{@port}/status")
    counter = 0
    loop do
      sleep(1)
      counter = counter + 1
      begin
        is_server_ready = Net::HTTP.get_response(uri).code.to_s == '200' ? true : false
      rescue
        is_server_ready = false
      end
      break if is_server_ready || counter >= time_limit
    end
    is_server_ready
  end

  def start_server
    if !is_server_ready? 1
      @pid = Process.spawn("ruby","#{PROJ_ROOT}/red-glass-app.rb")
      raise "Red Glass server could not bet started." if !is_server_ready?
      Process.detach @pid
    end
  end

  def set_config
    @port = @opts[:red_glass_port].nil? ? '4567' : @opts[:red_glass_port].to_s
    ENV['red_glass_port'] = @port
  end

  def load_js
    load_jQuery
    load_json2
    load_get_path
    load_red_glass_js
  end

  def load_jQuery
    has_jQuery = @driver.execute_script "var hasJQuery = typeof jQuery == 'function' ? true : false; return hasJQuery"
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/public/scripts/jquery-1.8.0.min.js"), 'rb').read
    @driver.execute_script raw_js if !has_jQuery
  end

  def load_json2
    has_old_json = @driver.execute_script "var hasOldJSON = typeof JSON.license == 'undefined' ? false : true; return hasOldJSON"
    @driver.execute_script "delete JSON" if has_old_json
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/public/scripts/json2.js"), 'rb').read
    @driver.execute_script raw_js
  end

  def load_get_path
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/public/scripts/jquery.getpath.js"), 'rb').read
    @driver.execute_script raw_js
  end

  def has_red_glass_js?
    @driver.execute_script "var hasRedGlass = typeof jQuery().redGlass == 'function' ? true : false; return hasRedGlass"
  end

  def load_red_glass_js
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/public/scripts/jquery.red-glass-0.1.0.js"), 'rb').read
    @driver.execute_script raw_js if !has_red_glass_js?
    @driver.execute_script("jQuery(document).redGlass('#{@test_id}', '#{@port}')")
    #@driver.execute_script "jQuery.noConflict(true)"
  end

end