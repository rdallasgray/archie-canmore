require 'rubygems'
require 'sinatra'
require 'json'
require_relative 'lib/canmore'

get '/' do 
end

get '/detail_rels_for/:lat/:long/:rad' do
  res = Canmore::Request.new().detail_rels_for(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  
  content_type 'text/javascript'
  "#{params[:callback]}(#{res.to_json});"
end

get '/details_for/:rel' do
  res = Canmore::Request.new().details_for params[:rel]
  
  content_type 'text/javascript'
  "#{params[:callback]}(#{res.to_json});"
end
