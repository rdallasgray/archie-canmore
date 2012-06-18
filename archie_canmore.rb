require 'rubygems'
require 'sinatra'
require 'json'
require 'httparty'
require 'silva'
require 'nokogiri'
require './request.rb'

get '/' do 
  content_type :json
  [].to_json
end

get '/:lat/:long/:rad' do
  content_type :json
  res = Canmore::Request.images_for_location(:lat => params[:lat].to_f, 
                                             :long => params[:long].to_f, 
                                             :rad => params[:rad].to_i)
  res.to_json
end
