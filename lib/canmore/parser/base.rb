module Canmore
  module Parser
    class Base
      def initialize(doc)
        @doc = Nokogiri::HTML(doc)
      end
    end
  end
end
