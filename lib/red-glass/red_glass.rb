require "selenium-webdriver"
require "uuid"
require "net/http"

class RedGlass
  attr_accessor :driver, :test_id, :opts, :port, :pid, :recording, :event_sequence, :page_metadata

  PROJ_ROOT = File.dirname(__FILE__).to_s

  def initialize(driver, opts={})
    @driver = driver
    @opts = opts
    opts[:listener].red_glass = self if opts[:listener]
    @test_id = opts[:test_id] || UUID.new.generate
    @event_sequence = []
    @page_metadata = {}
    @recording = false
  end

  def start
    set_config
    start_server
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

  def take_snapshot
    capture_page_metadata
    create_page_archive_directory
    take_screenshot
    capture_page_source
    write_metadata
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
      @pid = Process.spawn("ruby","#{PROJ_ROOT}/red-glass-app/red-glass-app.rb")
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
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/red-glass-app/public/scripts/jquery-1.8.0.min.js"), 'rb').read
    @driver.execute_script raw_js if !has_jQuery
  end

  def load_json2
    has_old_json = @driver.execute_script "var hasOldJSON = typeof JSON.license == 'undefined' ? false : true; return hasOldJSON"
    @driver.execute_script "delete JSON" if has_old_json
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/red-glass-js/json2.js"), 'rb').read
    @driver.execute_script raw_js
  end

  def load_get_path
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/red-glass-js/jquery.getpath.js"), 'rb').read
    @driver.execute_script raw_js
  end

  def has_red_glass_js?
    @driver.execute_script "var hasRedGlass = typeof jQuery().redGlass == 'function' ? true : false; return hasRedGlass"
  end

  def load_red_glass_js
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/red-glass-js/jquery.red-glass-0.1.0.js"), 'rb').read
    @driver.execute_script raw_js if !has_red_glass_js?
    @driver.execute_script("jQuery(document).redGlass('#{@test_id}', '#{@port}')")
    #@driver.execute_script "jQuery.noConflict(true)"
  end

  def create_page_archive_directory
    detect_archive_location
    Dir::mkdir construct_archive_path
  end

  def construct_archive_path
    "#{@opts[:archive_location].chomp('/')}/#{@page_metadata[:browser][:name]}_#{@page_metadata[:browser][:version]}_#{@page_metadata[:time]}"
  end

  def detect_archive_location
    unless @opts[:archive_location] && File.directory?(@opts[:archive_location])
      raise 'You must specify a valid archive location by passing an :archive_location option into the RedGlass initializer.'
    end
  end

  def capture_page_metadata
    @page_metadata[:test_id] = @test_id
    @page_metadata[:time] = Time.now.to_i
    @page_metadata[:page_url] = @driver.current_url
    @page_metadata[:browser] = {name: @driver.capabilities[:browser_name],
                                        version: @driver.capabilities[:version],
                                        platform: @driver.capabilities[:platform].to_s}
    @page_metadata[:event_sequence] = @event_sequence
  end

  def take_screenshot
    @driver.save_screenshot "#{construct_archive_path}/screenshot.png"
  end

  def capture_page_source
    File.open("#{construct_archive_path}/source.html", 'w') { |file| file.write @driver.page_source }
  end

  def write_metadata
    File.open("#{construct_archive_path}/metadata.json", 'w') { |file| file.write @page_metadata.to_json }
  end

end