require 'libxml'

module ROXML
  module XML # :nodoc:all

    class << self
      def set_attribute(node, name, value)
        node.attributes[name] = value
      end

      def set_content(node, content)
        node.content = content.gsub('&', '&amp;')
      end

      def new_node(name)
        LibXML::XML::Node.new(name)
      end

      def add_node(parent, name)
        add_child(parent, new_node(name))
      end

      def add_cdata(parent, content)
        add_child(parent, LibXML::XML::Node.new_cdata(content))
      end

      def add_child(parent, child)
        parent << child
        child
      end
    end

    Document = LibXML::XML::Document
    Node = LibXML::XML::Node
    Parser = LibXML::XML::Parser
    Error = LibXML::XML::Error

    module NamespacedSearch
      def search(xpath, roxml_namespaces = {})
        if namespaces.default
          roxml_namespaces = {:xmlns => namespaces.default.href}.merge(roxml_namespaces)
        end
        if roxml_namespaces.present?
          find(xpath, roxml_namespaces.map {|prefix, href| [prefix, href].join(':') })
        else
          find(xpath)
        end
      end
    end

    class Document
      include NamespacedSearch
      
      def default_namespace
        default = namespaces.default
        default.prefix || 'xmlns' if default
      end

    private
      delegate :namespaces, :to => :root
    end

    class Node
      include NamespacedSearch

      def default_namespace
        doc.default_namespace
      end
    end

    class Parser
      class << self
        def parse(str_data)
          string(str_data).parse
        end

        def parse_file(path)
          file(path).parse
        end

        def parse_io(stream)
          io(stream).parse
        end
      end
    end
  end
end