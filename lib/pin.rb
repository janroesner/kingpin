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

  # add a Pincaster record for self with in layer: self.class
  def add_pin
    Pincaster.add_record(self)
  end

  def pin
    Pincaster.get_record(self)
  end

  # returns objects longitude
  def pin_lng
    [:longitude, :long, :lng].each do |l|
      return self.send(l) if self.respond_to?(l)
    end
    return nil
  end

  # returns objects latitude
  def pin_lat
    [:latitude, :lati, :ltt, :lat].each do |l|
      return self.send(l) if self.respond_to?(l)
    end
    return nil
  end

end

###
# PinClassMethods - provides models new class methods
###

module PinClassMethods

end
