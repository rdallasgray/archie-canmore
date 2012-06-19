require 'HTTParty'
require 'silva'
require_relative 'parser'

module Canmore
  module Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    SEARCH_URL = "/en/results/"
    SEARCH_DEFAULT_PARAMS={ :site_country => 1, :image_only_chk => 1, :submit => 'search'}    
    THUMB_URL = "/images/m/"

    def self.get_html(url = CANMORE_URL, params = nil, client == HTTParty)
      client.get(CANMORE_URL + url, :query => params).body
    end    
    
    def self.search_by_location(radius, location)
      gridref = Silva::Location.from(:wgs84, :lat => location[:lat], :long => location[:long]).to(:gridref)
      params = SEARCH_DEFAULT_PARAMS.merge({ :ngr => gridref, :locat_xy_radius_m => radius })
      get_html(SEARCH_URL, params)
    end

    def self.images_for(radius, location)
      html = search_by_location(radius, location)
      image_details = []
      detail_links = Canmore::Parser::Search.new(html).detail_links
      detail_links.each {|link| image_details << image_details_for(link)}
      image_details
    end

    def self.image_details_for(link)
      image_detail = { :site_link => CANMORE_URL + link }
      html = get_html(link)
      parser = Canmore::Parser::Detail.new(html)
      ngr = parser.ngr
      location = Silva::Location.from(:gridref, :gridref => ngr).to(:wgs84)
      image_detail[:lat], image_detail[:long] = location.lat, location.long
      image_detail[:site_name] = parser.site_name
      image_rels = parser.image_rels
      image_detail[:thumb_link] = CANMORE_URL + THUMB_URL + image_rels.first
      image_detail[:no_images] = image_rels.count
      image_detail
    end
  end
end
