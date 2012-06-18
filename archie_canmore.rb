require 'rubygems'
require 'sinatra'
require 'json'
require 'httparty'
require 'silva'
require 'nokogiri'
require './request.rb'

get '/' do 
end

get '/:lat/:long/:rad' do
  res = Canmore::Request.images_for_location(:lat => params[:lat].to_f, :long => params[:long].to_f, :rad => params[:rad].to_i)
  json = res.to_json

  if params[:callback]
    json = "#{params[:callback]}(#{json});"
    content_type 'text/javascript'
  else
    content_type 'json'
  end

  json
end
