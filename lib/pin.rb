###
# Pin - makes models pinnable
###

module Pin
  class << self.class.superclass
    def pinnable
      include PinInstanceMethods
    end
  end
end

###
# PinInstanceMethods - provides models new instance methods
###

module PinInstanceMethods
  def self.included(base)
    base.extend PinClassMethods
  end

  def foo
    puts "foo"
  end
end

###
# PinClassMethods - provides models new class methods
###

module PinClassMethods
  def bar
    puts "bar"
  end
end
