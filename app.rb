require 'yaml'
require 'securerandom'
Bundler.require
Encoding.default_internal = 'binary'
Encoding.default_external = 'binary'
DIR_ROOT = File.expand_path File.dirname(__FILE__)
$config = YAML.load_file(File.join(DIR_ROOT, 'config.yml'))

SIGNAL_CODES = {
  0 => 'success',
  1 => 'missingargs',
  2 => 'slowjs',
  3 => 'openfailed',
  4 => 'resourcetimeout',
  5 => 'maxtimeout'
}

HARD_TIMEOUT = 30

SCREENSHOTS_TMPDIR = '/tmp/screenshots'

FileUtils.mkdir_p SCREENSHOTS_TMPDIR

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == 'screenshots' and password == $config['api_key']
end

get '/' do
  line = Cocaine::CommandLine.new(
    "DISPLAY=:0 timeout #{HARD_TIMEOUT} slimerjs screenshot.js", ":url :file_path :wait_time",
    expected_outcodes: [0]
  )

  file_tmp_path = File.join SCREENSHOTS_TMPDIR, "#{SecureRandom.uuid}.jpg"

  begin
    output = line.run url: params[:url], file_path: file_tmp_path, wait_time: (params[:wait_time] || 0)
  rescue Cocaine::ExitStatusError => e
    halt 500, SIGNAL_CODES[line.exit_status.to_i]
  end

  image_data = File.read file_tmp_path
  FileUtils.rm file_tmp_path

  content_type :jpg
  image_data
end
