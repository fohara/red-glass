require 'selenium-webdriver'
require 'uuid'
require 'net/http'
require 'open-uri'
require 'openssl'

class RedGlass
  attr_accessor :driver, :test_id, :opts, :port, :pid, :recording, :event_sequence, :page_metadata, :archive_dir

  PROJ_ROOT = File.dirname(__FILE__).to_s

  def initialize(driver, opts={})
    @driver = driver
    @opts = opts
    opts[:listener].red_glass = self if opts[:listener]
    @test_id = opts[:test_id] || UUID.new.generate
    @server_log = opts[:server_log] || false
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
    Process.kill('INT', @pid) if @pid
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

  def server_ready?(time_limit=60)
    ready, elapsed = false, 0
    until ready || elapsed >= time_limit
      begin
        http = Net::HTTP.new(server_uri.host, server_uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.get(server_uri.request_uri)
        ready = response.code.to_s == '200' ? true : false
      rescue
        ready = false
      end
      elapsed = increment_elapsed(elapsed) unless ready
    end
    ready
  end

  def increment_elapsed(elapsed)
    sleep 1
    elapsed + 1
  end

  def server_uri
    URI.parse("https://localhost:#{@port}/status")
  end

  def start_server
    unless server_ready? 1
      @pid = Process.spawn("ruby #{PROJ_ROOT}/red-glass-app/red-glass-app.rb")
      raise 'Red Glass server could not bet started.' unless server_ready?
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
    carryall_path = "#{PROJ_ROOT}/red-glass-js/redglass.carryall.js"
    encoded_lines = IO.readlines(File.expand_path(carryall_path)).map do |line|
      line.encode('ASCII-8BIT', :invalid => :replace, :undef => :replace)
    end
    File.open(carryall_path, "w") do |file|
      file.puts(encoded_lines)
    end
    raw_js = File.open(File.expand_path(carryall_path), 'rb').read
    @driver.execute_script raw_js
    @driver.execute_script("jQuery(document).redGlass({testId: '#{@test_id}', port: '#{@port}', useServerLog: #{@server_log}})")
  end

  def has_red_glass_js?
    @driver.execute_script "return typeof jQuery == 'function' && typeof jQuery().redGlass == 'function';"
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
    dom = JSON.parse(@driver.execute_script("return JSON.stringify(jQuery(document).redGlass('serializeDOM'));"),
                     { symbolize_names: true })
    dom[:browser] = @page_metadata[:browser][:name]
    @page_metadata[:doc_width] = dom[:width]
    @page_metadata[:doc_height] = dom[:height]
    write_serialized_dom(dom.to_json)
  end

end