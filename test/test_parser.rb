require 'minitest/spec'
require 'minitest/autorun'

require_relative '../lib/canmore'

describe Canmore::Parser::Search do
  before do
    search_html = File.read(File.dirname(__FILE__) + '/mock/search.html')
    @parser = Canmore::Parser::Search.new(search_html)
  end

  describe "given the search html" do
    it "should find six detail links" do
      @parser.detail_links.count.must_equal 6
    end
  end
end

describe Canmore::Parser::Detail do
  before do
    detail_html = File.read(File.dirname(__FILE__) + '/mock/detail.html')
    @parser = Canmore::Parser::Detail.new(detail_html)
  end
  
  describe "given the detail html" do
    it "should find the correct site name" do
      @parser.site_name.must_equal 'Glasgow, Belmont Street, Belmont Bridge'
    end
    it "should find the correct site grid reference" do
      @parser.ngr .must_equal 'NS5748567283'
    end
    it "should find four image rels" do
      @parser.image_rels.count.must_equal 4
    end
  end
end
