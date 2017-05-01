# coding: utf-8
require 'bundler'
Bundler.require

require 'sinatra'
require 'net/http'
require 'ipaddr'

enable :sessions

get '/oauth/:client_id/:scope/:domain' do
  return 403 if request.referer
  return 403 unless %r{\Ahttps://sim\d+\.agni\.lindenlab\.com\:\d+\/}.match(params[:sl])

  uri = URI.parse(params[:sl])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Get.new(uri.path)
  res = http.request(req)
  return 403 unless res.code == "200"

  session[:sl] = params[:sl]
  query = URI.encode_www_form("client_id" => params[:client_id],
                              "response_type" => "code",
                              "scope" => params[:scope],
                              "redirect_uri" => "#{request.base_url}/oauth/callback")
  redirect "https://#{params[:domain]}/oauth/authorize?" + query
end

get '/oauth/callback' do
  return 403 unless %r{\Ahttps://sim\d+\.agni\.lindenlab\.com\:\d+\/}.match(session[:sl])
  return 403 unless params[:code]

  uri = URI.parse(session[:sl])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Post.new(uri.path)
  req.body = params[:code]
  res = http.request(req)
  return 403 unless res.code == "200"
  
  [200, "このウィンドウはこのまま閉じてください"]
end

get '/streaming/:domain/:access_token' do
  # Simulator IP Addresses http://wiki.secondlife.com/wiki/Simulator_IP_Addresses
  return 403 unless %w(8.2.32.0/22 8.4.128.0/22 8.10.144.0/21 63.210.156.0/22 64.154.220.0/22 216.82.0.0/18).any? {|range| IPAddr.new(range).include?(request.ip)}
  return 403 unless request.env['HTTP_X_SECONDLIFE_SHARD'] == 'Production'
  
  domain = params.delete("domain")
  grid_url = URI.parse(params.delete("sl"))
  upstream_url = "https://#{domain}/api/v1/streaming?" + URI.encode_www_form(params)
  http = Net::HTTP.new(grid_url.host, grid_url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  ws = WebSocket::Client::Simple.connect(upstream_url)
  ws.on :message do |msg|
    if msg.data.size > 0
      toot = JSON.parse(msg.data)
      if toot["event"] == "update"
        status = JSON.parse(toot["payload"])
        acct = status["account"]["acct"]

        contents = Nokogiri::HTML.parse(status["content"])
        text = ''
        contents.search('p').children.each do |item|
          text += item.text.strip if item.text?
        end        
        
        req = Net::HTTP::Post.new(grid_url.path, {'Content-Type' => 'text/plain; charset=utf-8'})
        req.body = "#{acct}: #{text}"
        http.request(req)
      end
    end
  end

  ws.on :open do
    puts "streaming open"
  end

  ws.on :close do |e|
    puts "close"
    p e
  end

  ws.on :error do |e|
    p e
  end
  
  [200, "OK"]
end
