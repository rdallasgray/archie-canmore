module Canmore
  module Parser
    class Base
      def initialize(doc)
        @doc = Nokogiri::HTML(doc)
      end

      private
      
      def squeeze_line_breaks(str)
        str.gsub(/(\n<br\/>){2,}/, "<br/>").gsub(/\n{2,}/, "\n")
      end
    end
  end
end
