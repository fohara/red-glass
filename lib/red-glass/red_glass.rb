require 'selenium-webdriver'
require 'uuid'
require 'net/http'

class RedGlass
  attr_accessor :driver, :test_id, :opts, :port, :pid, :recording, :event_sequence, :page_metadata, :archive_dir

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
    load_js
    serialize_dom
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
    unless is_server_ready? 1
      @pid = Process.spawn("ruby","#{PROJ_ROOT}/red-glass-app/red-glass-app.rb")
      raise 'Red Glass server could not bet started.' unless is_server_ready?
      Process.detach @pid
    end
  end

  def set_config
    @port = @opts[:red_glass_port].nil? ? '4567' : @opts[:red_glass_port].to_s
    ENV['red_glass_port'] = @port
  end

  def load_js
    load_red_glass_carryall unless has_red_glass_js?
  end

  def load_red_glass_carryall
    raw_js = File.open(File.expand_path("#{PROJ_ROOT}/red-glass-js/redglass.carryall.js"), 'rb').read
    @driver.execute_script raw_js
    @driver.execute_script("jQuery(document).redGlass('#{@test_id}', '#{@port}')")
  end

  def has_red_glass_js?
    @driver.execute_script "var hasRedGlass = (typeof jQuery == 'function' && typeof jQuery().redGlass == 'function') ? true : false; return hasRedGlass"
  end

  def create_page_archive_directory
    detect_archive_location
    unless @archive_dir
      @archive_dir = "#{@opts[:archive_location].chomp('/')}/#{@test_id}"
      Dir::mkdir @archive_dir unless File.directory? @archive_dir
    end
    Dir::mkdir construct_page_archive_path
  end

  def construct_page_archive_path
    "#{@archive_dir}/#{@page_metadata[:browser][:name]}_#{@page_metadata[:browser][:version]}_#{@page_metadata[:time]}"
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
    @driver.save_screenshot "#{construct_page_archive_path}/screenshot.png"
  end

  def capture_page_source
    File.open("#{construct_page_archive_path}/source.html", 'w') { |file| file.write @driver.page_source }
  end

  def write_metadata
    File.open("#{construct_page_archive_path}/metadata.json", 'w') { |file| file.write @page_metadata.to_json }
  end

  def write_serialized_dom(dom_json_string)
    File.open("#{construct_page_archive_path}/dom.json", 'w') { |file| file.write dom_json_string }
  end

  def serialize_dom
    dom_json_string = "{\n\t\"browser\":" + "\"" + @page_metadata[:browser][:name] + "\","
    dom_json_string += "\n\t\"elements\":\n\t[\n\t"
    serialize_dom_js_string = stringify_serialize_dom_js
    dom_json_string += @driver.execute_script(serialize_dom_js_string + " return RecurseDomJSON(rgUtils.query('*'),'')")
    dom_json_string = dom_json_string[0, (dom_json_string.length - 3)] + "\n\t]\n}"
    @page_metadata[:doc_width] = @driver.execute_script(serialize_dom_js_string + ' return rgUtils.query(document).width()')
    @page_metadata[:doc_height] = @driver.execute_script(serialize_dom_js_string + ' return rgUtils.query(document).height()')
    write_serialized_dom dom_json_string
  end

  def stringify_serialize_dom_js
    domgun_recurse_dom_file = File.open("#{PROJ_ROOT}/red-glass-js/serialize-dom.js", 'rb')
    domgun_recurse_dom_string = domgun_recurse_dom_file.read
    domgun_recurse_dom_file.close
    domgun_recurse_dom_string
  end

end