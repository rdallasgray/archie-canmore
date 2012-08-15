require 'httparty'
require 'silva'
require_relative 'parser'
require_relative 'model/action_report'

module Canmore
  class Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    SEARCH_URL = "/en/results/"
    SEARCH_DEFAULT_PARAMS = { :site_country => 1, :image_only_chk => 1, :submit => 'search', :show => 'all' }
    DETAIL_URL = "/en/site/:id/details/"
    THUMB_URL = "/images/m/"
    IMAGE_URL = "/images/l/"

    def initialize(client = HTTParty)
      @client = client
    end

    ##
    # Return an array of six-digit numbers which can be used to find individual site records on Canmore,
    # given a lat/long location and a radius in which to search.
    #
    def site_ids_for_location(radius, location)
      html = search_by_location(radius, location)
      detail_links = Canmore::Parser::Search.new(html).detail_links
      six_digits = /site\/([0-9]{6})\//
      detail_links.select {|link| link.to_s =~ six_digits}.map {|link| link.to_s.match(six_digits)[1]}
    end

    def thumb_links_for_location(radius, location)
      html = search_by_location(radius, location)
      Canmore::Parser::Search.new(html).thumb_links.map {|link| CANMORE_URL + link}
    end

    def site_images_for_location(radius, location)
      site_ids = site_ids_for_location(radius, location)
      image_details = {}
      site_ids.each do |id|
        begin
          details = details_for_site_id(id)
          minimal_details = {
            :site_name => details[:site_name],
            :location => {
              :lat => details[:lat],
              :long => details[:long],
              :alt => rand(20) + 20
            },
            :imgUri => "#{CANMORE_URL}#{THUMB_URL}#{details[:images].first}/",
          }
          image_details[id] = minimal_details
        rescue
          puts $!, $@
        end
      end
      image_details
    end

    ##
    # Return a hash of details on a given site, given a six-digit rel to search on.
    #
    def details_for_site_id(id)
      link = detail_url_for_id(id)
      details = { :site_link => CANMORE_URL + link }
      html = get_html(link)
      parser = Canmore::Parser::Detail.new(html)
      image_ids = parser.image_ids
      ngr = parser.ngr
      location = Silva::Location.from(:gridref, :gridref => ngr).to(:wgs84)
      details[:site_id] = id
      details[:lat], details[:long] = location.lat, location.long
      details[:site_name] = parser.site_name
      details[:images] = image_ids.to_ary
      details[:site_description] = parser.site_description
      details
    end

    def image_for_id_at_size(id, size) 
      "#{CANMORE_URL}/images/#{size}/#{id}/"
    end

    def report_user_action(params)
      report = Canmore::Model::ActionReport.create(params)
      report
    end

    def user_actions()
      Canmore::Model::ActionReport.all
    end
      

    private

    def get_html(url, params = nil)
      puts "getting url #{CANMORE_URL + url} with params #{params.to_s}"
      if (cache_result = Canmore::Cache.get_request(url, params))
        return cache_result
      end
      response = @client.get(CANMORE_URL + url, :query => params)
      Canmore::Cache.put_request(url, params, response.body)
      response.body
    end

    def detail_url_for_id(id)
      DETAIL_URL.sub(/:id/, id)
    end

    def search_by_location(radius, location)
      gridref = Silva::Location.from(:wgs84, :lat => location[:lat], :long => location[:long]).to(:gridref)
      params = SEARCH_DEFAULT_PARAMS.merge({ :ngr => gridref.to_s, :locat_xy_radius_m => radius })
      get_html(SEARCH_URL, params)
    end
  end
end
