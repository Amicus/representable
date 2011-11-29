require 'json'
require 'representable/bindings/json_bindings'

module Representable
  # Brings #to_xml, #to_hash, #from_xml and #from_hash to your object.
  #
  # Note: The authorative methods are #to_hash and #from_hash, if you override #to_json instead,
  # things might work as expected.
  module JSON
    BINDING_FOR_TYPE = {  # TODO: refactor #representable_accessor for better extendability.
      :text     => TextBinding,
    }
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end
    
    
    module ClassMethods
      def binding_for_definition(definition)
        (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
      end
    
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Example:
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      # DISCUSS: assumes shitty wrapping like :article => {:name => ...}
      def from_json(data, *args, &block)
        create_from_json.tap do |object|
          object.from_json(data, *args, &block)
        end
      end
      
      def from_hash(data)
        create_from_json.tap do |object|
          object.update_properties_from(data)
        end
      end
      
    private
      def create_from_json(*args)
        new(*args)
      end
    end
    
    def from_json(data, options={}, &block)
      data = ::JSON[data]
      
      # DISCUSS: move wrapping to #from_hash for consistency.
      if wrap = options[:wrap] || self.class.representation_wrap
        data = data[wrap.to_s]
      end
      
      data ||= {} # FIXME: should we fail here? generate a warning?
      
      update_properties_from(data, &block)
    end
    
    def to_hash(options={})
      hash = create_representation_with({})
      
      return hash unless wrap = options[:wrap] || self.class.representation_wrap
      
      {wrap => hash}
    end
    
    # Returns a JSON string representing this object.
    def to_json(options={})
      to_hash(options).to_json
    end
  end
end
