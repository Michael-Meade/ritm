require 'json'
require 'thin'
require 'sinatra/base'

class ThinHttpsBackend < Thin::Backends::TcpServer
  def initialize(host, port, ssl_options)
    super(host, port)
    @ssl = true
    @ssl_options = ssl_options
  end
end

class WebServer < Sinatra::Base
  set :environment, :test
  set :server, :thin
  set :bind, '127.0.0.1'
  set :port, 4567
  set :logging, false
  disable :protection
  set :specs, {}

  @requests_count = 0

  class << self
    attr_accessor :requests_count
  end

  def self.run_async
    t = Thread.new { run! }
    trap(:TERM) { t.kill }
    trap(:INT) { t.kill }
    Thread.pass
  end

  def extract_headers(env)
    ret = {}
    env.each do |k, v|
      case k
        when 'CONTENT_LENGTH', 'CONTENT_TYPE'
          ret[k.downcase.gsub('_','-')] = v
        when /^HTTP_.*/
          h = k.dup
          h.slice!('HTTP_')
          ret[h.downcase.gsub('_','-')] = v
      end
    end
    ret
  end

  before do
    WebServer.requests_count +=1
  end

  get '/ping' do
    'pong'
  end

  [:get, :post, :put, :patch, :delete, :options].each do |method|
    send(method, '/echo') do
      request.body.rewind
      info = { method: request.request_method,
               path: request.path,
               query: request.query_string,
               headers: extract_headers(request.env),
               body: request.body.read.to_s }

      content_type 'application/json'
      info.to_json
    end
  end

  error do |e|
    "#{e.class}\n#{e.to_s}\n#{e.backtrace.join("\n")}"
  end
end

class SslWebServer < WebServer
  configure do
    set :environment, :test
    set :bind, '127.0.0.1'
    set :port, 4443
    set :logging, false
    set :server, :thin
    class << settings
      def server_settings
        {
          backend:  ThinHttpsBackend,
          private_key_file: test_path('resources/webserver.key'),
          cert_chain_file: test_path('resources/webserver.crt'),
          verify_peer: false
        }
      end
    end
  end
end

WebServer.run_async
SslWebServer.run_async
