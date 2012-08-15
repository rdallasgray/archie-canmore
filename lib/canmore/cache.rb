require 'digest/md5'

module Canmore
  module Cache
    @cache = {}

    def self.put_request(url, params, result)
      key = url + params.to_s
      self.put(key, result)
    end

    def self.get_request(url, params)
      key = url + params.to_s
      self.get(key)
    end

    def self.put(key, val)
      @cache[hash_key(key)] = val
    end

    def self.get(key)
      @cache[hash_key(key)]
    end

    def self.hash_key(key)
      Digest::MD5.hexdigest(key)
    end
  end
end
