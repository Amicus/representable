%w(extensions/active_support extensions/deprecation extensions/array extensions/string options xml).each do |file|
  require File.join(File.dirname(__FILE__), 'roxml', file)
end

module ROXML # :nodoc:
  VERSION = '2.4.1'

  def self.included(base) # :nodoc:
    base.extend ClassMethods::Accessors,
                ClassMethods::Declarations,
                ClassMethods::Operations
    base.class_eval do
      include InstanceMethods::Accessors,
              InstanceMethods::Construction,
              InstanceMethods::Conversions
    end
  end

  module InstanceMethods # :nodoc:
    # Instance method equivalents of the Class method accessors
    module Accessors # :nodoc:all
      # Provides access to ROXML::ClassMethods::Accessors::tag_name directly from an instance of a ROXML class
      def tag_name
        self.class.tag_name
      end
      deprecate :tag_name => 'use class.tag_name instead'

      # Provides access to ROXML::ClassMethods::Accessors::tag_refs directly from an instance of a ROXML class
      def tag_refs
        self.class.tag_refs_without_deprecation
      end
      deprecate :tag_refs => :roxml_attrs
    end

    module Construction
      # xml_initialize is called at the end of the #from_xml operation on objects
      # where xml_construct is not in place. Override xml_initialize in order to establish
      # post-import behavior.  For example, you can use xml_initialize to map xml attribute
      # values into the object standard initialize function, thus enabling a ROXML object
      # to freely be either xml-backed or instantiated directly via #new.
      # An example of this follows:
      #
      #  class Measurement
      #    include ROXML
      #
      #    xml_reader :units, :attr
      #    xml_reader :value, :content
      #
      #    def xml_initialize
      #      # the object is instantiated, and all xml attributes are imported
      #      # and available, i.e., value and units below are the same value and units
      #      # found in the xml via the xml_reader declarations above.
      #      initialize(value, units)
      #    end
      #
      #    def initialize(value, units = 'pixels')
      #      @value = Float(value)
      #      @units = units.to_s
      #      if @units.starts_with? 'hundredths-'
      #        @value /= 100
      #        @units = @units.split('hundredths-')[1]
      #      end
      #    end
      #  end
      #
      # #xml_initialize may be written to take arguments, in which case extra arguments
      # from from_xml will be passed into the function.
      #
      def xml_initialize
      end
    end

    module Conversions
      # Returns a LibXML::XML::Node or a REXML::Element representing this object
      def to_xml(name = nil)
        returning XML::Node.new_element(name || self.class.tag_name) do |root|
          self.class.roxml_attrs.each do |attr|
            ref = attr.to_ref(self)
            v = ref.to_xml
            unless v.nil?
              ref.update_xml(root, v)
            end
          end
        end
      end
    end
  end

  # This class defines the annotation methods that are mixed into your
  # Ruby classes for XML mapping information and behavior.
  #
  # See xml_name, xml_initialize, xml, xml_reader and xml_accessor for
  # available annotations.
  #
  module ClassMethods # :nodoc:
    module Declarations
      # Sets the name of the XML element that represents this class. Use this
      # to override the default lowercase class name.
      #
      # Example:
      #  class BookWithPublisher
      #   xml_name :book
      #  end
      #
      # Without the xml_name annotation, the XML mapped tag would have been "bookwithpublisher".
      #
      def xml_name(name)
        @roxml_tag_name = name
      end

      # Most xml documents have a consistent naming convention, for example, the node and
      # and attribute names might appear in CamelCase. xml_convention enables you to adapt
      # the roxml default names for this object to suit this convention.  For example,
      # if I had a document like so:
      #
      #  <XmlDoc>
      #    <MyPreciousData />
      #    <MoreToSee InAttrs="" />
      #  </XmlDoc>
      #
      # Then I could access it's contents by defining the following class:
      #
      #  class XmlDoc
      #    include ROXML
      #    xml_convention :camelcase
      #    xml_reader :my_precious_data
      #    xml_reader :in_attrs, :in => 'MoreToSee'
      #  end
      #
      # You may supply a block or any #to_proc-able object as the argument,
      # and it will be called against the default node and attribute names before searching
      # the document.  Here are some example declaration:
      #
      #  xml_convention :upcase
      #  xml_convention &:camelcase
      #  xml_convention {|val| val.gsub('_', '').downcase }
      #
      # See ActiveSupport::CoreExtensions::String::Inflections for more prepackaged formats
      #
      # Note that the xml_convention is also applied to the default root-level tag_name,
      # but in this case an underscored version of the name is applied, for convenience.
      def xml_convention(to_proc_able = nil, &block)
        raise ArgumentError, "conventions are already set" if @roxml_naming_convention
        raise ArgumentError, "only one conventions can be set" if to_proc_able.respond_to?(:to_proc) && block_given?
        @roxml_naming_convention = to_proc_able.try(:to_proc)
        @roxml_naming_convention = block if block_given?
      end

      def roxml_naming_convention # :nodoc:
        (@roxml_naming_convention || superclass.try(:roxml_naming_convention)).freeze
      end

      # Declares an accesser to a certain xml element, whether an attribute, a node,
      # or a typed collection of nodes.  Typically you should call xml_reader or xml_accessor
      # rather than calling this method directly, but the instructions below apply to both.
      #
      # == Sym Option
      # [sym]   Symbol representing the name of the accessor.
      #
      # === Default naming
      # This name will be the default node or attribute name searched for,
      # if no other is declared.  For example,
      #
      #  xml_reader   :bob
      #  xml_accessor :pony, :attr
      #
      # are equivalent to:
      #
      #  xml_reader   :bob, :from => 'bob'
      #  xml_accessor :pony, :attr => 'pony'
      #
      # === Boolean attributes
      # If the name ends in a ?, ROXML will attempt to coerce the value to true or false,
      # with True, TRUE, true and 1 mapping to true and False, FALSE, false and 0 mapping
      # to false, as shown below:
      #
      #  xml_reader :desirable?
      #  xml_reader :bizzare?, :attr => 'BIZZARE'
      #
      #  x = #from_xml(%{
      #    <object BIZZARE="1">
      #      <desirable>False</desirable>
      #    </object>
      #  })
      #  x.desirable?
      #  => false
      #  x.bizzare?
      #  => true
      #
      # If an unexpected value is encountered, the attribute will be set to nil,
      # unless you provide a block, in which case the block will recived
      # the actual unexpected value.
      #
      #  #from_xml(%{
      #    <object>
      #      <desirable>Dunno</desirable>
      #    </object>
      #  }).desirable?
      #  => nil
      #
      #  xml_reader :strange? do |val|
      #    val.upcase
      #  end
      #
      #  #from_xml(%{
      #    <object>
      #      <strange>Dunno</strange>
      #    </object>
      #  }).strange?
      #  => DUNNO
      #
      # == Type options
      # All type arguments may be used as the type argument to indicate just type,
      # or used as :from, pointing to a xml name to indicate both type and attribute name.
      # Also, any type may be passed via an array to indicate that multiple instances
      # of the object should be returned as an array.
      #
      # === :attr
      # Declare an accessor that represents an XML attribute.
      #
      # Example:
      #  class Book
      #   xml_reader :isbn, :attr => "ISBN" # 'ISBN' is used to specify :from
      #   xml_accessor :title, :attr        # :from defaults to :title
      #  end
      #
      # To map:
      #  <book ISBN="0974514055" title="Programming Ruby: the pragmatic programmers' guide" />
      #
      # === :text
      # The default type, if none is specified. Declares an accessor that
      # represents a text node from XML.
      #
      # Example:
      #  class Book
      #    xml_reader :author, :text => 'Author'
      #    xml_accessor :description, :text, :as => :cdata
      #    xml_reader :title
      #  end
      #
      # To map:
      #  <book>
      #   <title>Programming Ruby: the pragmatic programmers' guide</title>
      #   <description><![CDATA[Probably the best Ruby book out there]]></description>
      #   <Author>David Thomas</author>
      #  </book>
      #
      # Likewise, a number of :text node values can be collected in an array like so:
      #
      # Example:
      #  class Library
      #    xml_reader :books, [:text], :in => 'books'
      #  end
      #
      # To map:
      #  <library>
      #    <books>
      #      <book>To kill a mockingbird</book>
      #      <book>House of Leaves</book>
      #      <book>Gödel, Escher, Bach</book>
      #    </books>
      #  </library>
      #
      # === :content
      # A special case of :text, this refers to the content of the current node,
      # rather than a sub-node
      #
      # Example:
      #  class Contributor
      #    xml_reader :name, :content
      #    xml_reader :role, :attr
      #  end
      #
      # To map:
      #  <contributor role="editor">James Wick</contributor>
      #
      # === Hash
      # Somewhere between the simplicity of a :text/:attr mapping, and the complexity of
      # a full Object/Type mapping, lies the Hash mapping.  It serves in the case where you have
      # a collection of key-value pairs represented in your xml.  You create a hash declaration by
      # passing a hash mapping as the type argument.  A few examples:
      #
      # ==== Hash of :attrs
      # For xml such as this:
      #
      #    <dictionary>
      #      <definitions>
      #        <definition dt="quaquaversally"
      #                    dd="adjective: (of a geological formation) sloping downward from the center in all directions." />
      #        <definition dt="tergiversate"
      #                    dd="To use evasions or ambiguities; equivocate." />
      #      </definitions>
      #    </dictionary>
      #
      # You can use the :attrs key in you has with a [:key, :value] name array:
      #
      #    xml_reader :definitions, {:attrs => ['dt', 'dd']}, :in => :definitions
      #
      # ==== Hash of :texts
      # For xml such as this:
      #
      #    <dictionary>
      #      <definition>
      #        <word/>
      #        <meaning/>
      #      </definition>
      #      <definition>
      #        <word/>
      #        <meaning/>
      #      </definition>
      #    </dictionary>
      #
      # You can individually declare your key and value names:
      #    xml_reader :definitions, {:key => 'word',
      #                              :value => 'meaning'}
      #
      # ==== Hash of :content &c.
      # For xml such as this:
      #
      #    <dictionary>
      #      <definition word="quaquaversally">adjective: (of a geological formation) sloping downward from the center in all directions.</definition>
      #      <definition word="tergiversate">To use evasions or ambiguities; equivocate.</definition>
      #    </dictionary>
      #
      # You can individually declare the key and value, but with the attr, you need to provide both the type
      # and name of that type (i.e. {:attr => :word}), because omitting the type will result in ROXML
      # defaulting to :text
      #    xml_reader :definitions, {:key => {:attr => 'word'},
      #                              :value => :content}
      #
      # ==== Hash of :name &c.
      # For xml such as this:
      #
      #    <dictionary>
      #      <quaquaversally>adjective: (of a geological formation) sloping downward from the center in all directions.</quaquaversally>
      #      <tergiversate>To use evasions or ambiguities; equivocate.</tergiversate>
      #    </dictionary>
      #
      # You can pick up the node names (e.g. quaquaversally) using the :name keyword:
      #    xml_reader :definitions, {:key => :name,
      #                              :value => :content}
      #
      # === Other ROXML Class
      # Declares an accessor that represents another ROXML class as child XML element
      # (one-to-one or composition) or array of child elements (one-to-many or
      # aggregation) of this type. Default is one-to-one. Use :array option for one-to-many, or
      # simply pass the class in an array.
      #
      # Composition example:
      #  <book>
      #   <publisher>
      #     <name>Pragmatic Bookshelf</name>
      #   </publisher>
      #  </book>
      #
      # Can be mapped using the following code:
      #   class Book
      #     xml_reader :publisher, Publisher
      #   end
      #
      # Aggregation example:
      #  <library>
      #   <books>
      #    <book/>
      #    <book/>
      #   </books>
      #  </library>
      #
      # Can be mapped using the following code:
      #  class Library
      #    xml_reader :books, [Book], :in => "books"
      #  end
      #
      # If you don't have the <books> tag to wrap around the list of <book> tags:
      #  <library>
      #   <name>Ruby books</name>
      #   <book/>
      #   <book/>
      #  </library>
      #
      # You can skip the wrapper argument:
      #    xml_reader :books, [Book]
      #
      # == Blocks
      # You may also pass a block which manipulates the associated parsed value.
      #
      #  class Muffins
      #    include ROXML
      #
      #    xml_reader(:count, :from => 'bakers_dozens') {|val| val.to_i * 13 }
      #  end
      #
      # For hash types, the block recieves the key and value as arguments, and they should
      # be returned as an array of [key, value]
      #
      # For array types, the entire array is passed in, and must be returned in the same fashion.
      #
      # === Block Shorthands
      #
      # Alternatively, you may use block shorthands to specify common coercions, such that:
      #
      #  xml_reader :count, :as => Integer
      #
      # is equivalent to:
      #
      #  xml_reader(:count) {|val| Integer(val) }
      #
      # Block shorthands :float, Float, :integer and Integer are currently available,
      # but only for non-Hash declarations.
      #
      # == Other options
      # [:from] The name by which the xml value will be found, either an attribute or tag name in XML.  Default is sym, or the singular form of sym, in the case of arrays and hashes.
      # [:as] one or more of the following: :cdata for character data; Integer, Float, Date, Time or DateTime to coerce to the respective type
      # [:in] An optional name of a wrapping tag for this XML accessor
      # [:else] Default value for attribute, if missing
      # [:required] If true, throws RequiredElementMissing when the element isn't present
      # [:frozen] If true, all results are frozen (using #freeze) at parse-time.
      #
      def xml_reference(writable, sym, type_and_or_opts = :text, opts = nil, &block)
        opts = Opts.new(sym, *[type_and_or_opts, opts].compact, &block)

        add_accessor(opts, writable)
      end

      def xml(sym, writable = false, type_and_or_opts = :text, opts = nil, &block) #:nodoc:
        xml_reference(writable, sym, type_and_or_opts, opts, &block)
      end
      deprecate :xml => :xml_reference

      # Declares a read-only xml reference. See xml for details.
      #
      # Note that while xml_reader does not create a setter for this attribute,
      # its value can be modified indirectly via methods.  For more complete
      # protection, consider the :frozen option.
      def xml_reader(sym, type_and_or_opts = :text, opts = nil, &block)
        xml_reference false, sym, type_and_or_opts, opts, &block
      end

      # Declares a writable xml reference. See xml for details.
      #
      # Note that while xml_accessor does create a setter for this attribute,
      # you can use the :frozen option to prevent its value from being
      # modified indirectly via methods.
      def xml_accessor(sym, type_and_or_opts = :text, opts = nil, &block)
        xml_reference true, sym, type_and_or_opts, opts, &block
      end

      # This method is deprecated, please use xml_initialize instead
      def xml_construct(*args) # :nodoc:
        present_tags = tag_refs_without_deprecation.map(&:accessor)
        missing_tags = args - present_tags
        unless missing_tags.empty?
          raise ArgumentError, "All construction tags must be declared first using xml, " +
                               "xml_reader, or xml_accessor. #{missing_tags.join(', ')} is missing. " +
                               "#{present_tags.join(', ')} are declared."
        end
        @xml_construction_args = args
      end
      deprecate :xml_construct => :xml_initialize

    private
      def add_accessor(attr, writable)
        if roxml_attrs.map(&:accessor).include? attr.accessor
          raise "Accessor #{attr.accessor} is already defined as XML accessor in class #{self.name}"
        end
        @roxml_attrs << attr

        define_method(attr.accessor) do
          result = instance_variable_get("@#{attr.variable_name}")
          if result.nil?
            result = attr.default
            instance_variable_set("@#{attr.variable_name}", result)
          end
          result
        end

        if writable && !instance_methods.include?("#{attr.accessor}=")
          attr_writer(attr.accessor)
        end
      end
    end

    module Accessors
      def xml_construction_args # :nodoc:
        @xml_construction_args ||= []
      end
      deprecate :xml_construction_args

      # A helper which enables us to detect when the xml_name has been explicitly set
      def xml_name? #:nodoc:
        @roxml_tag_name
      end
      deprecate :xml_name?

      # Returns the tag name (also known as xml_name) of the class.
      # If no tag name is set with xml_name method, returns default class name
      # in lowercase.
      #
      # If xml_convention is set, it is called with an *underscored* version of
      # the class name.  This is because active support's inflector generally expects
      # an underscored version, and several operations (e.g. camelcase(:lower), dasherize)
      # do not work without one.
      def tag_name
        return roxml_tag_name if roxml_tag_name
        
        if tag_name = name.split('::').last
          roxml_naming_convention ? roxml_naming_convention.call(tag_name.underscore) : tag_name.downcase
        end
      end

      def roxml_tag_name # :nodoc:
        @roxml_tag_name || superclass.try(:roxml_tag_name)
      end

      # Returns array of internal reference objects, such as attributes
      # and composed XML objects
      def roxml_attrs
        @roxml_attrs ||= []
        (@roxml_attrs + (superclass.try(:roxml_attrs) || [])).freeze
      end

      def tag_refs # :nodoc:
        roxml_attrs.map {|a| a.to_ref(nil) }
      end
      deprecate :tag_refs => :roxml_attrs
    end

    module Operations
      #
      # Creates a new Ruby object from XML using mapping information
      # annotated in the class.
      #
      # The input data is either an XML::Node or a String representing
      # the XML document.
      #
      # Example
      #  book = Book.from_xml(File.read("book.xml"))
      # or
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      #
      # _initialization_args_ passed into from_xml will be passed into
      # the object #xml_initialize method.
      #
      # See also: xml_initialize
      #
      def from_xml(data, *initialization_args)
        xml =
          if data.is_a?(XML::Node)
            data
          elsif data.is_a?(File)
            XML::Parser.parse_file(data).root
          elsif (defined?(:URI) && data.is_a?(URI::Generic)) ||
                (defined?(:Pathname) && data.is_a?(Pathname))
            XML::Parser.parse_file(data.to_s).root
          else
            XML::Parser.parse(data).root
          end

        unless xml_construction_args_without_deprecation.empty?
          args = xml_construction_args_without_deprecation.map do |arg|
             roxml_attrs.find {|attr| attr.accessor == arg }
          end.map {|attr| attr.to_ref(self).value_in(xml) }
          new(*args)
        else
          returning allocate do |inst|
            roxml_attrs.each do |attr|
              inst.instance_variable_set("@#{attr.variable_name}", attr.to_ref(inst).value_in(xml))
            end
            inst.send(:xml_initialize, *initialization_args)
          end
        end
      end

      # Deprecated in favor of #from_xml
      def parse(data) # :nodoc:
        from_xml(data)
      end
      deprecate :parse => :from_xml
    end
  end
end

