require 'httparty'
require 'silva'
require_relative 'parser'

module Canmore
  module Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    SEARCH_URL = "/en/results/"
    SEARCH_DEFAULT_PARAMS={ :site_country => 1, :image_only_chk => 1, :submit => 'search'}    
    THUMB_URL = "/images/m/"

    def self.get_html(url = CANMORE_URL, params = nil, client = HTTParty)
      client.get(CANMORE_URL + url, :query => params).body
    end    
    
    def self.search_by_location(radius, location)
      gridref = Silva::Location.from(:wgs84, :lat => location[:lat], :long => location[:long]).to(:gridref)
      params = SEARCH_DEFAULT_PARAMS.merge({ :ngr => gridref, :locat_xy_radius_m => radius })
      get_html(SEARCH_URL, params)
    end

    def self.detail_rels_for(radius, location)
      html = search_by_location(radius, location)
      image_details = []
      detail_links = Canmore::Parser::Search.new(html).detail_links
      six_digit_rel = /site\/([0-9]{6})\//
      detail_links.select {|link| link.match(six_digit_rel)}.map {|link| link.match(six_digit_rel)[0]}
    end

    def self.details_for(rel)
      link = "/en/site/#{rel}/details/"
      details = { :site_link => CANMORE_URL + link }
      html = get_html(link)
      parser = Canmore::Parser::Detail.new(html)
      image_rels = parser.image_rels
      ngr = parser.ngr
      location = Silva::Location.from(:gridref, :gridref => ngr).to(:wgs84)
      details[:lat], details[:long] = location.lat, location.long
      details[:site_name] = parser.site_name
      details[:thumb_link] = CANMORE_URL + THUMB_URL + image_rels.first + '/'
      details[:no_images] = image_rels.count
      details
    end
  end
end
