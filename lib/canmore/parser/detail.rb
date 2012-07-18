module Canmore
  module Parser
    class Detail < Base
      def site_name
        name = @doc.xpath("//div[@id='map']//h1/span/text()").to_s
        sanitize name
      end

      def site_description
        headings = @doc.xpath("//h3[@class='clearl']")
        content_sections = @doc.xpath("//h3[@class='clearl']/following-sibling::p[1]")
        details = ""
        headings.zip(content_sections).each do |h, c| 
          details << "<h3>#{sanitize(h.to_s)}</h3>" 
          details << "<p>#{sanitize(c.to_s)}</p>"
        end
        details
      end

      def ngr
        detail_text = @doc.xpath("//div[@id='padding']/p[1]/text()")
        detail_text.to_s.match(/[HJNOST][A-Z]\s?[0-9]{3,5}\s?[0-9]{3,5}/)[0].delete(" ")
      end

      def image_ids
        @doc.xpath("//div[@id='mygallery']//a/@rel")
      end
    end
  end
end
