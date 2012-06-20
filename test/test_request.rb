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

  describe "#detail_rels_for" do
    search_url = Canmore::Request::CANMORE_URL + Canmore::Request::SEARCH_URL
    location = { :lat => 55.8791, :long => -4.2787 }
    ngr = "NS57546745"
    radius = 250
    search_params = Canmore::Request::SEARCH_DEFAULT_PARAMS.merge({ :ngr => ngr, :locat_xy_radius_m => radius })

    describe "given a radius and location" do
      it "should send a properly-formed get request to the client" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        rels = @request.detail_rels_for(radius, location)
        @client.verify
      end
      it "should return an array of length six" do
        @client.expect :get, @search_html_response, [search_url, :query => search_params]
        rels = @request.detail_rels_for(radius, location)
        rels.count.must_equal 6
      end
    end
  end

  describe "#details_for" do
    rel = '160711'
    url = Canmore::Request::CANMORE_URL +  Canmore::Request::DETAIL_URL.sub(/:rel/, rel)
    details_hash = {
      :site_link => 'http://canmore.rcahms.gov.uk/en/site/160711/details/',
      :lat => 55.877559,
      :long => -4.279605,
      :site_name => 'Glasgow, Belmont Street, Belmont Bridge',
      :thumb_link => 'http://canmore.rcahms.gov.uk/images/m/411468/',
      :no_images => 4
     }

    describe "given a 6-digit rel" do
      it "should send a properly-formed get request to the client" do
        @client.expect :get, @detail_html_response, [url, :query => nil]
        details = @request.details_for(rel)
        @client.verify
      end
      it "should return the correct hash" do
        @client.expect :get, @detail_html_response, [url, :query => nil]
        details = @request.details_for(rel)
        details.must_equal details_hash
      end
    end
  end
end
