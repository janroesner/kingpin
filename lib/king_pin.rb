###
# Kingpin - makes models pinnable
###

module Kingpin
  class << self.class.superclass
    def pinnable(*args)
      include KingpinInstanceMethods
      self.kingpin_args = args
      named_scope :nearby, lambda { |point, radius| { :conditions => ["id in (?)", point.nearby_ids(radius)] } }
      after_save :autopin if (!!args.first[:autopin] rescue false)
    end
  end
end

###
# KingpinInstanceMethods - provides models new instance methods
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
    if not !!self.class.kingpin_args[:methods]
      [:longitude, :long, :lng, :lgt, :lgtd, :lngtd].each do |l|
        if self.respond_to?(l)
          return !!self.class.kingpin_args[:rad] ? self.send(l).to_f * 180 / Math::PI : self.send(l)
        end
      end
      return nil
    else
      return !!self.class.kingpin_args[:rad] ? self.send(self.class.kingpin_args[:methods][:lng]).to_f * 180.0 / Math::PI : self.send(self.class.kingpin_args[:methods][:lng])
    end
  end

  # returns objects latitude depending on configured method name for access as well as DEG or RAD configuration
  def pin_lat
    if not !!self.class.kingpin_args[:methods]
      [:latitude, :lati, :ltt, :ltd, :lat, :lttd].each do |l|
        if self.respond_to?(l)
          return !!self.class.kingpin_args[:rad] ? self.send(l).to_f * 180 / Math::PI : self.send(l)
        end
      end
      return nil
    else
      return !!self.class.kingpin_args[:rad] ? self.send(self.class.kingpin_args[:methods][:lat]).to_f * 180.0 / Math::PI : self.send(self.class.kingpin_args[:methods][:lat])
    end
  end

  # automatically adds a pin via after_save hook for self in case autopin option was set to true for self's AR model
  def autopin
    self.add_pin
  end

  # returns additional attributes of self that shall be included into the pin
  def additional_attributes
    return {} unless !!self.class.kingpin_args[:include]
    case self.class.kingpin_args[:include].class.to_s
    when "Symbol"
      raise ":all is the only stand alone symbol that is allowed with :include" unless self.class.kingpin_args[:include] == :all
      self.attributes
    when "Hash"
      if self.class.kingpin_args[:include].size > 1 or not [:only, :except].include? self.class.kingpin_args[:include].first.first
        raise ":include supports :only => [:foo, :bar] and :except => [:scooby, :doo] only"
      end
      case self.class.kingpin_args[:include].first.first
      when :only
        self.attributes.delete_if{ |name, value| !self.class.kingpin_args[:include].first[1].include?(name.to_sym) }
      when :except
        self.attributes.delete_if{ |name, value| self.class.kingpin_args[:include].first[1].include?(name.to_sym) }
      end
    else
      raise ":include needs :all, {:only => [:foo, :bar]} or {:except => [:scooby, :doo]}"
    end
  end

end

###
# KingpinClassMethods - provides models new class methods
###

module KingpinClassMethods

  def kingpin_args=(args)
    @@kingpin_args = args.empty? ? nil : args
  end

  def kingpin_args
    @@kingpin_args.first rescue {:methods => nil, :rad => false, :autopin => false}
  end

end
