module Canmore
  module Parser
    ##
    # Simple base class from which detail and search parsers extend.
    class Base
      require 'sanitize'
      
      ##
      # Initialise the parser with an HTML document.
      # @param doc [String] An HTML document as a string.
      def initialize(doc)
        @doc = Nokogiri::HTML(doc)
      end

      private

      def sanitize(html)
        cleaned = Sanitize.clean(html)
        cleaned.squeeze(" ").strip().gsub(/\n/, "<p>")
      end
    end
  end
end
