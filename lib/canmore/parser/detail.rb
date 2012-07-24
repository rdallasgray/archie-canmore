module Canmore
  module Parser
    class Detail < Base
      require 'erubis'

      def site_name
        name = @doc.xpath("//div[@id='map']//h1/span/text()").to_s
        sanitize name
      end

      def site_description
        headings = @doc.xpath("//h3[@class='clearl']")
        content_sections = @doc.xpath("//h3[@class='clearl']/following-sibling::p[1]")
        content = ""
        headings.zip(content_sections).each do |h, c| 
          unless (c.to_s().squeeze().empty?)
            content << "<h3>#{sanitize(h.to_s)}</h3>" 
            content << "<p>#{sanitize(c.to_s)}"
          end
        end
        rhtml = IO.read(File.expand_path("site_description.rhtml", File.dirname(__FILE__)))
        content_html = Erubis::Eruby.new(rhtml)
        content_html.result(:content => content)
      end

      def ngr
        detail_text = @doc.xpath("//div[@id='padding']/p[1]/text()")
        detail_text.to_s.match(/[HJNOST][A-Z]\s?[0-9]{3,5}\s?[0-9]{3,5}/)[0].delete(" ")
      end

      def image_ids
        links = @doc.xpath("//div[@id='mygallery']//a/@href").to_ary
        links.map {|link| link.to_s.split("/").last }
      end
    end
  end
end
