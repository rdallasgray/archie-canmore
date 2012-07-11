module Canmore
  module Parser
    class Search < Base
      def detail_links
        @doc.xpath("//tbody//a[contains(@href, '/details/')]/@href")
      end

      def thumb_links
        @doc.xpath("//tbody//img[@class='list_thumb']/@src").map {|link| link.to_s.gsub(/\/s\//, "/m/")}
      end
    end
  end
end
