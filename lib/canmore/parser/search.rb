module Canmore
  module Parser
    ##
    # Parser used to scrape Canmore search results pages.
    class Search < Base
      
      ##
      # Get an array of links to site details pages.
      # @return [Array] An array of urls.
      def detail_links
        @doc.xpath("//tbody//a[contains(@href, '/details/')]/@href")
      end

      ##
      # Get an array of links to thumbnail images.
      # @return An array of urls.
      def thumb_links
        @doc.xpath("//tbody//img[@class='list_thumb']/@src").map {|link| link.to_s.gsub(/\/s\//, "/m/")}
      end
    end
  end
end
