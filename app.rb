# coding: utf-8
require 'sinatra'
require 'net/http'

enable :sessions

get '/oauth/:client_id/:scope/:domain' do
  return 403 if request.referer
  return 403 unless %r{\Ahttps://sim\d+\.agni\.lindenlab\.com\:\d+\/}.match(params[:sl])

  uri = URI.parse(request[:sl])
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  req = Net::HTTP::Get.new(uri.path)
  res = http.request(req)
  return 403 unless res.code == "200"

  session[:sl] = request[:sl]
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
