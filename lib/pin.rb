module Pin
  class << self.class.superclass
    def pinnable
      include PinInstanceMethods
    end
  end
end

module PinInstanceMethods
  def self.included(base)
    base.extend PinClassMethods
  end

  def foo
    puts "foo"
  end
end

module PinClassMethods
  def bar
    puts "bar"
  end
end
