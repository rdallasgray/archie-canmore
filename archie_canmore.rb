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

get '/site_ids_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().site_ids_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue => error
    puts "Error: #{error.to_s}"
    res = []
  end
    content_type 'text/javascript'
    "#{params[:callback]}(#{res.to_json});"
end

get '/thumb_links_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().thumb_links_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue => error
    puts "Error: #{error.to_s}"
    res = []
  end
    content_type 'text/javascript'
    "#{params[:callback]}(#{res.to_json});"
end

get '/details_for_site_id/:id' do
  begin
    res = Canmore::Request.new().details_for_site_id params[:id]
  rescue => error
    puts "Error: #{error.to_s}"
    res = []
  end
    content_type 'text/javascript'
    "#{params[:callback]}(#{res.to_json});"
end
