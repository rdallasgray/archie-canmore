require 'rubygems'
require 'sinatra'
require 'json'
require_relative 'lib/canmore'

get '/site_ids_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().site_ids_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    puts $!, $@
    res = []
  end
  return_result res, params[:callback]
end

get '/site_images_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().site_images_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    puts $!, $@
    res = []
  end
  return_result res, params[:callback]
end

get '/thumb_links_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().thumb_links_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    puts $!, $@
    res = []
  end
  return_result res, params[:callback]
end

get '/details_for_site_id/:id' do
  begin
    res = Canmore::Request.new().details_for_site_id params[:id]
  rescue
    puts $!, $@
    res = []
  end
  return_result res, params[:callback]
end

get '/image_for_id_at_size/:id/:size' do
  begin
    res = Canmore::Request.new().image_for_id_at_size params[:id], params[:size]
  rescue
    puts $!, $@
    halt 404
  end
  redirect res
end

get '/report_user_action' do
  begin
    res = Canmore::Request.new().report_user_action params
  rescue
    puts $!, $@
    halt 404
  end
  return_result res, params[:callback]
end

get '/user_actions' do
  begin
    res = Canmore::Request.new().user_actions
  rescue
    puts $!, $@
    halt 404
  end
  return_result res, params[:callback]
end


def return_result(res, callback)
  content_type 'text/javascript'
  json = res.to_json
  unless callback
    return json
  end
  "#{callback}(#{json});"
end

