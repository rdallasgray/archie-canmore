module Canmore
  module Request
    CANMORE_URL = "http://canmore.rcahms.gov.uk"
    THUMB_URL = "/images/m/"
    SEARCH_URL = "/en/results/"
    DEFAULT_PARAMS={ :site_country => 1, :image_only_chk => 1, :submit => 'search'}
    
    def self.images_for_location(location)
      gridref = ::Silva::Location.from(:wgs84, :lat => location[:lat], :long => location[:long], :alt => 0).to(:gridref)
      html = fetch_response(gridref.to_s, location[:rad])
      retrieve_image_details_from(html)
    end

    def self.fetch_response(gridref, rad)
      options = { :query => { :ngr => gridref, :locat_xy_radius_m => rad  }.merge(DEFAULT_PARAMS) }
      response = HTTParty.get(CANMORE_URL + SEARCH_URL, options)
      response.body
    end

    def self.retrieve_image_details_from(html)
      details = []
      html_doc = Nokogiri::HTML(html)
      detail_links = html_doc.xpath("//tbody//a[contains(@href, '/details/')]/@href")
      detail_links.each do |link|
        details << get_details_for(link)
      end
      details
    end

    def self.get_details_for(link)
      abs_link = CANMORE_URL + link
      details = {}
      html_doc = Nokogiri::HTML(HTTParty.get(abs_link + link))
      details[:site_name] = html_doc.xpath("//div[@id='map']//h1/span/text()")
      details[:site_link] = abs_link

      detail_text = html_doc.xpath("//div[@id='padding']/p[1]/text()")
      ngr = detail_text.to_s.match(/[HJNOST][A-Z]\s?[0-9]{3,5}\s?[0-9]{3,5}/)[0].delete(" ")
      wgs84 = Silva::Location.from(:gridref, :gridref => ngr).to(:wgs84)
      details[:lat] = wgs84.lat
      details[:long] = wgs84.long

      image_rels = html_doc.xpath("//div[@id='mygallery']//a/@rel")
      details[:no_images] = image_rels.count
      details[:thumb_link] = CANMORE_URL + THUMB_URL + image_rels.first + "/"

      details
    end
  end
end
