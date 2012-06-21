require 'rubygems'
require 'sinatra'
require 'json'
require_relative 'lib/canmore'

get '/' do 
end

get '/dev/test' do
  send_file File.expand_path('archie_test.html', 'architect/')
end

get '/dev/js/:file' do
  send_file File.expand_path(params[:file], 'architect/lib/')
end

get '/dev/css/:file' do
  send_file File.expand_path(params[:file], 'public/stylesheets/')
end

get '/detail_rels_for/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().detail_rels_for(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    res = []
  end
    content_type 'text/javascript'
    "#{params[:callback]}(#{res.to_json});"
end

get '/details_for/:rel' do
  begin
    res = Canmore::Request.new().details_for params[:rel]
  rescue
    res = []
  end
    content_type 'text/javascript'
    "#{params[:callback]}(#{res.to_json});"
end
