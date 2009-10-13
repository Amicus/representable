require 'nokogiri'

module ROXML
  module XML # :nodoc:all
    Document = Nokogiri::XML::Document
    Element = Nokogiri::XML::Element
    Node = Nokogiri::XML::Node

    module Error
      def self.reset_handler
        # noop
      end
    end

    class Parser
      class << self
        def parse(string)
          Nokogiri::XML(string)
        end

        def parse_file(path) #:nodoc:
          parse(open(path))
        end

        def parse_io(stream) #:nodoc:
          parse(path)
        end
      end
    end

    module NodeExtensions
      def search(xpath)
        super("./#{xpath}")
      end
    end

    class Element
      include NodeExtensions

      def empty?
        children.empty?
      end
    end

    class Node
      class << self
        def from(xml)
          Nokogiri::XML(xml)
        end

        def create(name)
          new(name, Document.new)
        end
      end
      include NodeExtensions
      alias :remove! :remove
    end
  end
end