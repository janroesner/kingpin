module Pin
  class << self.class.superclass
    def pinnable
      self.send(:class_variable_set, :@@magic_methods, args.first)
      include PinInstanceMethods
    end
  end
end

module PinInstanceMethods
  def self.included(base)
    base.extend PinClassMethods
  end

  def foo
    puts foo
  end
end

module PinClassMethods
  def bar
    puts "bar"
  end
end
