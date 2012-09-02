require 'httparty'
require 'silva'
require_relative 'parser'
require_relative 'model/action_report'
require_relative 'cache'

module Canmore
  ##
  # Encapsulates logic to make requests to and retrieve responses from the Canmore archive.
  class Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    SEARCH_URL = "/en/results/"
    SEARCH_DEFAULT_PARAMS = { :site_country => 1, :image_only_chk => 1, :submit => 'search', :show => 'all' }
    DETAIL_URL = "/en/site/:id/details/"
    THUMB_URL = "/images/m/"
    IMAGE_URL = "/images/l/"

    ##
    # Initialize, passing an HTTP client and cache. Defaults are HTTParty and Dalli.
    # @param client An HTTP client object.
    # @param cache A cache object.
    def initialize(client = HTTParty, cache = Canmore::Cache)
      @client = client
      @cache = cache
    end

    ##
    # Get an array of six-digit numbers which can be used to find individual site records on Canmore,
    # given a lat/long location and a radius in which to search.
    # @param [Float] radius The radius, in metres, within which to search.
    # @param [Hash] location A hash of :lat => [Float], :long => [Float]
    # @return [Array] An array of six-digit id numbers.
    def site_ids_for_location(radius, location)
      html = search_by_location(radius, location)
      detail_links = Canmore::Parser::Search.new(html).detail_links
      six_digits = /site\/([0-9]{6})\//
      detail_links.select {|link| link.to_s =~ six_digits}.map {|link| link.to_s.match(six_digits)[1]}
    end

    ##
    # Get a hash of (minimal) details for sites found within the given radius of the location.
    # @param [Float] radius The radius, in metres, within which to search.
    # @param [Hash] location A hash of :lat => [Float], :long => [Float]
    # @return [Hash] A hash, indexed on site ids, with form :site_name => [String], :location => {:lat => [Float], :long => [Float]}, :imgUri => [String]
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
            :imgUri => "#{CANMORE_URL}#{THUMB_URL}#{details[:images].first}/"
          }
          image_details[id] = minimal_details
        rescue
          puts $!, $@
        end
      end
      image_details
    end

    ##
    # Get a hash of details on a given site, given a six-digit site id.
    # @param id [Integer] A six-digit site id.
    # @return [Hash] A has of site details in the form :site_link => [String], :site_id => [Integer], :lat => [Float], :long => [Float], :site_name => [String], :images => [Array], site_description => [String]
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

    ##
    # Get the url for an image with given id and size.
    # @param id [String] An image id.
    # @param size [String] s, m or l.
    def image_for_id_at_size(id, size) 
      "#{CANMORE_URL}/images/#{size}/#{id}/"
    end

    ##
    # Save a report of a user action for evaluation purposes.
    # @param params [Hash] A hash of parameters which can include :id => [String], :action => [String], :time => [DateTime], :run_id => [String], :device_id => [String], :battery_level => [Float], :lat => [Float], :long => [Float]
    # @return An ActionReport model initialised with the given parameters.
    def report_user_action(params)
      report = Canmore::Model::ActionReport.create(params)
      report
    end

    ##
    # Get the full list of stored user actions.
    # @return A collection of ActionReport models representing all stored action reports.
    def user_actions()
      Canmore::Model::ActionReport.all
    end
      

    private

    def get_html(url, params = nil)
      puts "getting url #{CANMORE_URL + url} with params #{params.to_s}"
      if (cache_result = @cache.get_request(url, params))
        return cache_result
      end
      response = @client.get(CANMORE_URL + url, :query => params)
      @cache.put_request(url, params, response.body)
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
