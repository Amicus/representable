require 'representable/binding'

module Representable
  module YAML
    class YAMLBinding < Representable::Binding
      def initialize(definition) # FIXME. make generic.
        super
        extend ObjectBinding if definition.typed?
      end
      
      def read(hash)
        return FragmentNotFound unless hash.has_key?(definition.from) # DISCUSS: put it all in #read for performance. not really sure if i like returning that special thing.
        
        fragment = hash[definition.from]
        deserialize_from(fragment)
      end
      
      def write(parent, value)
        parent.children << Psych::Nodes::Mapping.new.tap do |map|
          map.children << Psych::Nodes::Scalar.new(definition.from)
          map.children << serialize_for(value)  # FIXME: should be serialize.
        end
      end
    end
    
    
    class PropertyBinding < YAMLBinding
      def serialize_for(value)
        puts "serialize: #{value.inspect}"
        serialize_scalar serialize(value)
      end
      
      def deserialize_from(fragment)
        deserialize(fragment)
      end

      def serialize_scalar(value)
        Psych::Nodes::Scalar.new(value)
      end
    end
    
    
    class CollectionBinding < PropertyBinding
      def serialize_for(value)
        puts "collect: #{value.inspect}"
        Psych::Nodes::Sequence.new.tap do |seq|
          value.each { |obj| seq.children << super(obj) }
          #seq.children << Psych::Nodes::Scalar.new("yoho")
        end
      end
      
      def deserialize_from(fragment)
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
  end
end