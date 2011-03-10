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

  # add a Pincaster record for self with layer: self.class BUT self's lng and lat are in RAD not DEG
  def add_pin_rad
    Pincaster.add_record_rad(self)
  end

  # returns the Pincaster pin for self
  def pin
    Pincaster.get_record(self)
  end

  # deletes the Pincaster pin for self
  def delete_pin!
    Pincaster.delete_record(self)
  end

  # returns nearby Pincaster pins in given radius of self
  def nearby(radius)
    Pincaster.nearby(self, radius)
  end

  # returns nearby Pincaster pins in given radius of self BUT self's lat and lng are in RAD not DEG
  def nearby_rad(radius)
    Pincaster.nearby(self, radius, rad=true)
  end

  # returns objects longitude
  def pin_lng
    [:longitude, :long, :lng, :lgt, :lgdt].each do |l|
      return self.send(l) if self.respond_to?(l)
    end
    return nil
  end

  # returns objects latitude
  def pin_lat
    [:latitude, :lati, :ltt, :ltd, :lat].each do |l|
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
