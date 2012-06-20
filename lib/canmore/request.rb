require 'httparty'
require 'silva'
require_relative 'parser'

module Canmore
  class Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    SEARCH_URL = "/en/results/"
    SEARCH_DEFAULT_PARAMS = { :site_country => 1, :image_only_chk => 1, :submit => 'search'}
    DETAIL_URL = "/en/site/:rel/details/"
    THUMB_URL = "/images/m/"

    def initialize(client = HTTParty)
      @client = client
    end

    ##
    # Return an array of six- or seven-digit numbers which can be used to find individual site records on Canmore,
    # given a lat/long location and a radius in which to search.
    #
    def detail_rels_for(radius, location)
      html = search_by_location(radius, location)
      image_details = []
      detail_links = Canmore::Parser::Search.new(html).detail_links
      six_or_seven_digits = /site\/([0-9]{6,7})\//
      detail_links.select {|link| link.to_s =~ six_or_seven_digits}.map {|link| link.to_s.match(six_or_seven_digits)[1]}
    end

    ##
    # Return a hash of details on a given site, given a six/seven-digit rel to search on.
    #
    def details_for(rel)
      link = DETAIL_URL.sub(/:rel/, rel)
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

    private

    def get_html(url, params = nil)
      response = @client.get(CANMORE_URL + url, :query => params)
      response.body
    end
    
    def search_by_location(radius, location)
      gridref = Silva::Location.from(:wgs84, :lat => location[:lat], :long => location[:long]).to(:gridref)
      params = SEARCH_DEFAULT_PARAMS.merge({ :ngr => gridref.to_s, :locat_xy_radius_m => radius })
      get_html(SEARCH_URL, params)
    end
  end
end
