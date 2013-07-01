require "virtus"

module Representable::Coercion
  class Coercer
    include Virtus

    def coerce(name, v) # TODO: test me.
      # set and get the value as i don't know where exactly coercion happens in virtus.
      send("#{name}=", v)
      send(name)
    end
  end
  # separate coercion object doesn't give us initializer and accessors in the represented object (with module representer)!

  def self.included(base)
    base.class_eval do
      extend ClassMethods

      representable_attrs.instance_eval do
        def coercer_class
          @coercer_class ||= Class.new(Coercer)
        end
      end
    end
  end

  module ClassMethods
    def property(name, args={})
      return super unless args[:type]

      representable_attrs.coercer_class.instance_eval do
        attribute(name, args[:type])
      end

      # DISCUSS: we add accessors here, basically to provide the same API as before. also, we don't wanna override :getter here, do we?
      # TODO: deprecate these accessors for 1.7 and use coercer.coerce here, too.
      define_method(name) do
        coercer.send(name)
      end
      define_method("#{name}=") do |v|
        coercer.send("#{name}=", v)
      end

      super
    end
  end

  def coercer
    @coercer ||= representable_attrs.coercer_class.new
  end
end
