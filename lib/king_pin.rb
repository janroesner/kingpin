###
# Kingpin - makes models pinnable
###

module Kingpin
  class << self.class.superclass
    def pinnable(*args)
      include KingpinInstanceMethods
      self.kingpin_args = args
      named_scope :nearby, lambda { |point, radius| { :conditions => ["id in (?)", point.nearby_ids(radius)] } }
      after_save :autopin if !!args.first[:autopin]
    end
  end
end

###
# PinInstanceMethods - provides models new instance methods
###

module KingpinInstanceMethods
  def self.included(base)
    base.extend KingpinClassMethods
  end

  # add a Pincaster record for self with in layer: self.class
  def add_pin
    Pincaster.add_record(self)
  end

  # returns the Pincaster pin for self
  def pin
    Pincaster.get_record(self)
  end

  # deletes the Pincaster pin for self
  def delete_pin!
    Pincaster.delete_record(self)
  end

  # returns nearby found record_ids in same layer as self, radius meters away, number of results limited to limit
  def nearby_ids(radius, limit=nil)
    JSON.parse(Pincaster.nearby(self, radius, limit))["matches"].map{|p| p["key"]}
  end

  # returns nearby found records in same layer as self, radius metera away, number of results limited to limit
  def nearby(radius, limit=nil)
    self.class.find(nearby_ids(radius, limit))
  end

  # returns objects longitude depending on configured method name for access as well as DEG or RAD configuration
  def pin_lng
    if self.class.kingpin_args.nil?
      [:longitude, :long, :lng, :lgt, :lgdt].each do |l|
        return self.send(l) if self.respond_to?(l)
      end
      return nil
    else
      if !!self.class.kingpin_args[:methods]
        return !!self.class.kingpin_args[:rad] ? self.send(self.class.kingpin_args[:methods][:lng]).to_f * 180.0 / Math::PI : self.send(self.class.kingpin_args[:methods][:lng])
      else
        return self.send(self.class.kingpin_args[:methods][:lng])
      end
    end
  end

  # returns objects latitude depending on configured method name for access as well as DEG or RAD configuration
  def pin_lat
    if self.class.kingpin_args.nil?
      [:latitude, :lati, :ltt, :ltd, :lat].each do |l|
        return self.send(l) if self.respond_to?(l)
      end
      return nil
    else
      if !!self.class.kingpin_args[:methods]
        return !!self.class.kingpin_args[:rad] ? self.send(self.class.kingpin_args[:methods][:lat]).to_f * 180.0 / Math::PI : self.send(self.class.kingpin_args[:methods][:lat])
      else
        return self.send(self.class.kingpin_args[:methods][:lat])
      end
    end
  end

  # automatically adds a pin via after_save hook for self in case autopin option was set to true for self's AR model
  def autopin
    self.add_pin
  end

end

###
# PinClassMethods - provides models new class methods
###

module KingpinClassMethods

  def kingpin_args=(args)
    @@kingpin_args = args
  end

  def kingpin_args
    @@kingpin_args.first
  end

end
