require 'digest/md5'
require 'dalli'

set :cache, Dalli::Client.new

module Canmore
  ##
  # Manage caching of html returned from the Canmore archive.
  module Cache
    ##
    # Put a response in the cache, indexed using the url and params of the request.
    # @param [String] url The url of the request.
    # @param [Hash] params The params passed in the request.
    # @param [String] result The response to cache.
    def self.put_request(url, params, result)
      key = url + params.to_s
      self.put(key, result)
    end

    ##
    # Retrieve a response from the cache, indexed using the url and params of the request.
    # @param [String] url The url of the request.
    # @param [Hash] params The params passed in the request.
    # @return [String] A cached response.
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
