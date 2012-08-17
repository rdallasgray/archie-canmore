require 'data_mapper'
DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_VIOLET_URL'] || 'postgres://localhost/canmore')


module Canmore
  module Model
    class ActionReport
      include DataMapper::Resource
      
      property :id, Serial
      property :action, String
      property :time, DateTime
      property :run_id, String
      property :device_id, String
      property :battery_level, Float
      property :lat, Float
      property :long, Float
    end
  end
end
  
DataMapper.finalize
DataMapper.auto_migrate!
