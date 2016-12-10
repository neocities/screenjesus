require 'yaml'
require 'securerandom'
Bundler.require
Encoding.default_internal = 'binary'
Encoding.default_external = 'binary'
DIR_ROOT = File.expand_path File.dirname(__FILE__)
$config = YAML.load_file(File.join(DIR_ROOT, 'config.yml'))

`export DISPLAY=:0`

SIGNAL_CODES = {
  0 => 'success',
  1 => 'missingargs',
  2 => 'slowjs',
  3 => 'openfailed',
  4 => 'resourcetimeout',
  5 => 'maxtimeout'
}

HARD_TIMEOUT = 30

use Rack::Auth::Basic, "Restricted Area" do |username, password|
  username == 'screenshots' and password == $config['api_key']
end

get '/' do
  line = Cocaine::CommandLine.new(
    "timeout #{HARD_TIMEOUT} slimerjs screenshot.js", ":url :wait_time",
    expected_outcodes: [0]
  )

  begin
    output = line.run url: params[:url], wait_time: (params[:wait_time] || 0)
  rescue Cocaine::ExitStatusError => e
    halt 500, SIGNAL_CODES[line.exit_status.to_i]
  end

  content_type :jpg
  output
end
