require 'libxml'

module ROXML
  module XML
    include LibXML::XML
  end

  #
  # Internal base class that represents an XML - Class binding.
  #
  class XMLRef
    attr_reader :accessor, :name, :array, :default, :block

    def initialize(accessor, args, &block)
      @accessor = accessor
      @array = args.array?
      @name = args.name
      @default = args.default
      @block = block
    end

    # Reads data from the XML element and populates the instance
    # accordingly.
    def populate(xml, instance)
      data = value(xml)
      instance.instance_variable_set("@#{accessor}", data) if data
      instance
    end
  end

  # Interal class representing an XML attribute binding
  #
  # In context:
  #  <element attribute="XMLAttributeRef">
  #   XMLTextRef
  #  </element>
  class XMLAttributeRef < XMLRef
    # Updates the attribute in the given XML block to
    # the value provided.
    def update_xml(xml, value)
      xml.attributes[name] = value.to_utf
      xml
    end

    def value(xml)
      val = xml.attributes[name] || default
      block ? block.call(val) : val
    end
  end

  # Interal class representing XML content text binding
  #
  # In context:
  #  <element attribute="XMLAttributeRef">
  #   XMLTextRef
  #  </element>
  class XMLTextRef < XMLRef
    attr_reader :cdata, :wrapper, :text_content

    def initialize(accessor, args, &block)
      super(accessor, args, &block)
      @text_content = args.text_content?
      @cdata = args.cdata?
      @wrapper = args.wrapper
    end

    # Updates the text in the given _xml_ block to
    # the _value_ provided.
    def update_xml(xml, value)
      parent = wrap(xml)
      if text_content
        parent.content = text(value)
      elsif array
        value.each do |v|
          parent.add_element(name).content = text(v)
        end
      else
        parent.add_element(name).content = text(value)
      end
      xml
    end

    def value(xml)
      val = if text_content
        xml.content
      elsif array
        arr = xml.find(xpath).collect do |e|
          e.content.strip.to_latin if e.content
        end
        arr unless arr.empty?
      else
        child = xml.find_first(name)
        child.content if child
      end || default
      block ? block.call(val) : val
    end

  private
    def text(value)
      cdata ? XML::Node.new_cdata(value.to_utf) : value.to_utf
    end

    def xpath
      wrapper ? "#{wrapper}/#{name}" : name.to_s
    end

    def wrap(xml)
      wrapper ? xml.add_element(wrapper) : xml
    end
  end

  class XMLHashRef < XMLTextRef
    def initialize(accessor, args, &block)
      super(accessor, args, &block)
      @hash = args.hash
      @keys = to_ref(args.hash.key, args)
      @vals = to_ref(args.hash.value, args)
    end

    def value(xml)
      vals = xml.find(xpath).collect do |e|
        [@keys.value(e), @vals.value(xml)]
      end
      if block
        vals.collect! do |(key, val)|
          block.call(key, val)
        end
      end
      vals.to_h
    end

  private
    def to_ref(desc, args)
      case desc[:type]
      when :attr
        XMLAttributeRef.new(nil, args.to_hash_args(desc))
      when :text
        XMLTextRef.new(nil, args.to_hash_args(desc))
      when Symbol
        XMLTextRef.new(nil, args.to_hash_args(desc))
      else
        raise ArgumentError, "Missing key description #{desc.pp_s}"
      end
    end
  end

  class XMLObjectRef < XMLTextRef
    attr_reader :klass

    def initialize(accessor, args, &block)
      super(accessor, args, &block)
      @klass = args.type
    end

    # Updates the composed XML object in the given XML block to
    # the value provided.
    def update_xml(xml, value)
      parent = wrap(xml)
      unless array
        parent.add_element(value.to_xml)
      else
        value.each do |v|
          parent.add_element(v.to_xml)
        end
      end
      xml
    end

    def value(xml)
      val = unless array
        if child = xml.find_first(xpath)
          instantiate(child)
        end
      else
        arr = xml.find(xpath).collect do |e|
          instantiate(e)
        end
        arr unless arr.empty?
      end || default
      block ? block.call(val) : val
    end

  private
    def instantiate(elem)
      if klass.respond_to? :parse
        klass.parse(elem)
      else
        klass.new(elem)
      end
    end
  end

  #
  # Returns an XML::Node representing this object.
  #
  def to_xml
    returning XML::Node.new_element(tag_name) do |root|
      tag_refs.each do |ref|
        if v = __send__(ref.accessor)
          root = ref.update_xml(root, v)
        end
      end
    end
  end
end