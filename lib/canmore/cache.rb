require 'digest/md5'
require 'dalli'

set :cache, Dalli::Client.new

module Canmore
  module Cache
    def self.put_request(url, params, result)
      key = url + params.to_s
      self.put(key, result)
    end

    def self.get_request(url, params)
      key = url + params.to_s
      self.get(key)
    end

    def self.put(key, val)
      settings.cache.set(hash_key(key), val)
    end

    def self.get(key)
      settings.cache.get(hash_key(key))
    end

    def self.hash_key(key)
      Digest::MD5.hexdigest(key)
    end
  end
end
