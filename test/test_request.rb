require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/canmore'

Response = Struct.new('Response', :body)

describe Canmore::Request do
  before do
    @client = MiniTest::Mock.new
    @request = Canmore::Request.new(@client)
    @search_html_response = Response.new(File.read(File.dirname(__FILE__) + '/mock/search.html'))
    @detail_html_response = Response.new(File.read(File.dirname(__FILE__) + '/mock/detail.html'))
  end

  describe "#site_ids_for_location" do
    search_url = Canmore::Request::CANMORE_URL + Canmore::Request::SEARCH_URL
    location = { :lat => 55.8791, :long => -4.2787 }
    ngr = "NS57546745"
    radius = 250
    search_params = Canmore::Request::SEARCH_DEFAULT_PARAMS.merge({ :ngr => ngr, :locat_xy_radius_m => radius })

    describe "given a radius and location" do
      it "should send a properly-formed get request to the client" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        ids = @request.site_ids_for_location(radius, location)
        @client.verify
      end
      it "should return an array of length six" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        ids = @request.site_ids_for_location(radius, location)
        ids.count.must_equal 6
      end
    end
  end

  describe "#thumb_links_for_location" do
    search_url = Canmore::Request::CANMORE_URL + Canmore::Request::SEARCH_URL
    location = { :lat => 55.8791, :long => -4.2787 }
    ngr = "NS57546745"
    radius = 250
    search_params = Canmore::Request::SEARCH_DEFAULT_PARAMS.merge({ :ngr => ngr, :locat_xy_radius_m => radius })

    describe "given a radius and location" do
      it "should send a properly-formed get request to the client" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        ids = @request.thumb_links_for_location(radius, location)
        @client.verify
      end
      it "should return an array of length six" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        ids = @request.thumb_links_for_location(radius, location)
        ids.count.must_equal 6
      end
    end
  end

  describe "#details_for_site_id" do
    id = '160711'
    url = Canmore::Request::CANMORE_URL +  Canmore::Request::DETAIL_URL.sub(/:id/, id)
    details_hash_keys = [:site_link, :lat, :long, :site_name, :images, :site_description]

    describe "given a 6-digit id" do
      it "should send a properly-formed get request to the client" do
        @client.expect :get, @detail_html_response, [url, :query => nil]
        details = @request.details_for_site_id(id)
        @client.verify
      end
      it "should return the correct hash" do
        @client.expect :get, @detail_html_response, [url, :query => nil]
        details = @request.details_for_site_id(id)
        details.keys.must_equal details_hash_keys
      end
    end
  end
end
