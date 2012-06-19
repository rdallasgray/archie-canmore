module Canmore
  module Parser
    class Detail < Base
      def site_name
        @doc.xpath("//div[@id='map']//h1/span/text()").to_s
      end

      def ngr
        detail_text = @doc.xpath("//div[@id='padding']/p[1]/text()")
        detail_text.to_s.match(/[HJNOST][A-Z]\s?[0-9]{3,5}\s?[0-9]{3,5}/)[0].delete(" ")
      end

      def image_rels
        @doc.xpath("//div[@id='mygallery']//a/@rel")
      end
    end
  end
end
