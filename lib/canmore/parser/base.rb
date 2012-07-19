module Canmore
  module Parser
    class Base
      require 'sanitize'

      def initialize(doc)
        @doc = Nokogiri::HTML(doc)
      end

      private

      def sanitize(html)
        cleaned = Sanitize.clean(html)
        cleaned.squeeze(" ").strip().gsub(/\n/, "<br/><br/>")
      end
    end
  end
end
