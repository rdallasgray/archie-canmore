require 'rubygems'
require 'sinatra'
require 'json'
require_relative 'lib/canmore'

get '/' do 
end

get '/images_for/:lat/:long/:rad' do
  res = Canmore::Request.images_for(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  json = res.to_json

  if params[:callback]
    json = "#{params[:callback]}(#{json});"
    content_type 'text/javascript'
  else
    content_type 'json'
  end

  json
end
