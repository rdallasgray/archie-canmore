require 'rubygems'
require 'sinatra'
require 'json'
require_relative 'lib/canmore'

# Return a set of site ids for the given latitude, longitude and radius.
get '/site_ids_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().site_ids_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    p $!
    puts $@
    res = []
  end
  return_result res, params[:callback]
end

# Return details of images  for the given latitude, longitude and radius.
get '/site_images_for_location/:lat/:long/:rad' do
  begin
    res = Canmore::Request.new().site_images_for_location(params[:rad].to_i, :lat => params[:lat].to_f, :long => params[:long].to_f)
  rescue
    p $!
    puts $@
    res = []
  end
  return_result res, params[:callback]
end

# Return details for the given site id.
get '/details_for_site_id/:id' do
  begin
    res = Canmore::Request.new().details_for_site_id params[:id]
  rescue
    p $!
    puts $@
    res = []
  end
  return_result res, params[:callback]
end

# Get the image for the given id at size [s, m, l].
get '/image_for_id_at_size/:id/:size' do
  begin
    res = Canmore::Request.new().image_for_id_at_size params[:id], params[:size]
  rescue
    p $!
    puts $@
    halt 404
  end
  redirect res
end

# Report a user action for evaluation purposes.
get '/report_user_action' do
  begin
    res = Canmore::Request.new().report_user_action params
  rescue
    p $!
    puts $@
    res = []
  end
  return_result res, params[:callback]
end

# Return a list of stored user actions.
get '/user_actions' do
  begin
    res = Canmore::Request.new().user_actions
  rescue
    p $!
    puts $@
    res = []
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

