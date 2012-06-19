module Canmore
  module Parser
    class Search < Base
      def detail_links
        @doc.xpath("//tbody//a[contains(@href, '/details/')]/@href")
      end
    end
  end
end
