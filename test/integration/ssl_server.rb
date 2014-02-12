require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'
require 'sinatra/multi_route'

name = "/C=US/ST=SomeState/L=SomeCity/O=Organization/OU=Unit/CN=localhost"
ca   = OpenSSL::X509::Name.parse(name)
key = OpenSSL::PKey::RSA.new(1024)
crt = OpenSSL::X509::Certificate.new
crt.version = 2
crt.serial  = 1
crt.subject = ca
crt.issuer = ca
crt.public_key = key.public_key
crt.not_before = Time.now
crt.not_after  = Time.now + 1 * 365 * 24 * 60 * 60 # 1 year
webrick_options = {
    :Port               => 8443,
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => crt,
    :SSLPrivateKey      => key,
    :SSLCertName        => [[ "CN", WEBrick::Utils::getservername ]],
}

class SslServer < Sinatra::Base
  register Sinatra::MultiRoute

  get '/ping' do
    "1"
  end

  route :get, :post, :put, :delete, "/bands/bodyjar" do
    #protected!
    %{{"name": "Bodyjar"}}
  end
end
server = ::Rack::Handler::WEBrick

server.run(SslServer, webrick_options)