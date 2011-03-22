Kingpin
========

Kingpin is a Ruby gem that provides seamless integration of [Pincaster](https://github.com/jedisct1/Pincaster) into every ActiveRecord model in Rails 2 and 3.

Pincaster is a very fast memory driven but persisting **NoSQL** (yeah..) DB engine for fast geolocation operations. Kingpin directly integrates Pincaster into every ActiveRecord model that has at least real or virtual attributes for latitude and longitude. After indexing all of your objects you can easily request objects around your query object. Kingpin therefore provides several methods as well as named scopes and perfectly maps all operations that usually had to be taken manually.

Pincaster supports different layers that can be used to distinguish the kind of objects to be stored. Kingpin automatically creates a layer per ActiveRecord model and uses the class name as layer name. Every indexed AR object then is provided with a related Pincaster object - in this scope called a 'pin'. These pins can be used for fast nearby retrieval as well as distance calculation.

Prerequisites
-------------

* Install Frank Denis's [Pincaster](https://github.com/jedisct1/Pincaster)
* Configure Pincaster according to your needs
* Choose a proper 'Accuracy' method in pincaster.conf / I recommend: 'rhomboid'
* Startup Pincaster

Installation
------------

Kingpin is a gem available via [Rubygems.org](http://www.rubygems.org). To install it, simply put it into your Rails3 app's Gemfile:

    gem 'kingpin', '0.x.0'

and afterwards run bundler:

    bundle install

In case you are on Rails 2 without bundler support add Kingpin to your environment.rb as you are used to with other gems and install it via:

    rake gems:install

or:

    gem install kingpin

Congrats, you're done!


Configuration
-------------

Kingpin comes with it's own default configuration file that is loaded in case none is provided by the user. Create your own one at:

    config/kingpin.yml

with YAML formatted content like that:

    ---
    protocol: http
    host: localhost
    port: 4269
    namespace: '/api/1.0'

Do not forget the '- - -' and don't mess with spaces or tabs, it's [YAML](http://www.yaml.org). Adjust the values to your needs. Most recent versions of Pincaster support http only afaik, so you should not change it. Same with the namespace, changing it results in 404 responses for your requests.


Integration
-----------

Integration into you models is straight forward. Assuming that your model has an attribute_reader or accessor_method like one of the following:
    [:latitude, :lati, :ltt, :ltd, :lat, :lttd]

as well as one of the following for longitude:

    [:longitude, :long, :lng, :lgt, :lgtd, :lngtd]

**and** the values are in *DEG* **not** *RAD*, your way of integration looks like that:

    class FooWithLocation
      pinnable
      ...
    end


Either way, Kingpin tries to minimize your pain, so some configuration options are provided as well:

* `:methods => {:lat => :your_latitude, :lng => :your_longitude}` in case your location accessors have different names
* `:rad => true` defaults to *false* if not mentioned, and assumes your lat and lng in *RAD* instead of *DEG*
* `:autopin => true` automatically generates a Pincaster record every time an instance of an enabled model is saved
* `:include => :all | {:only => [:attr_1, :attr_2, ...]} | {:except => [:attr_1, :attr_2, ...]}`

Example: In case your longitude resides at :cool_longitude, your latitude at :cool_latitude, the values are stored in *RAD* and you would like to automatically create Pincaster pins, your classes head should look like this:

    class FooWithLocation
      pinnable :methods => { :lat => :cool_latitude, :lng => :cool_longitude }, :rad => true, :autopin => true
      ...
    end

In case you would like to integrate the instances values for :name and :title only into the pin, your class definition looked like that:

    class FooWithLocation
      pinnable :include => {:only => [:name, :title]}
      ...
    end

Vice versa `:include => {:except => [:name, :title]}` would integrate all attributes but :name and :title, `:include => :all` integrated all available attributes of the instance.

Indexing
--------

Next you should create some pins. The most recent version of Kingpin does not provide a Raketask for that automatically, but it will in the next release. You could create one on your own and make it look like the following: 


    namespace :kingpin do
      desc "Rebuild Pincaster index for FooWithLocations"
      task :reindex_foo_with_locations => :environment do
        if Pincaster.is_alive?
          1.upto(FooWithLocation.find(:last).id) do |i|
            begin
              STDOUT.print "indexed: " + i.to_s + "\r"
              FooWithLocation.find(i).add_pin
              STDOUT.flush
            rescue
            end
          end
        else
          puts "Pincaster seems to be down!\n"
        end
        puts "Finished reindexing FooWithLocations.\n"
      end
    end

Invocation
----------

Kingpin comes with some high- and some low-level operations you can use.

**Highlevel operations**

*Instance methods*

* nearby_ids(n,limit) - returns the id's of those foo's which are in range of n meters
* nearby(n,limit) - returns an array of fully fledged AR records within a range of n meters

Please have a look at the Pincaster doc's to fully understand how *limit* works. It's not supposed to work like the typical SQL like limit. If ommitted it defaults to 10000.

Example:

    foo = FooWithLocation.find(4711)
    foo.nearby_ids(500)

Example:

    foo = FooWithLocation.find(42)
    foo.nearby(500)

*Class methods - speak (named) scope*

* nearby(location, n)

nearby returns a named scope (sorry, no Rails3 scope available yet) that can be chained as you are used to.

Example:

    foo = FooWithLocation.find(23)
    FooWithLocation.nearby(foo, 500)

**Low level operations**

You would like to gain control over pins to be created? No problem. Kingpin provides the following instance methods for every enabled ActiveRecord model:

    foo = FooWithLocation.find(23)

* `foo.add_pin` - adds a pin for self
* `foo.pin` - returns an existing pin for self or nil
* `foo.delete_pin!` - deletes an existing pin
* `foo.nearby_ids(radius, limit)` - returns an array of AR instance id's in given radius of self
* `foo.nearby(radius, limit)` - returns an array of AR objects in given radius of self
* `foo.pin_lat` - returns self's normalized latitude (in DEG)
* `foo.pin_lng` - returns self's normalized longitude (in DEG)

There are also some Pincaster related methods that are bound to a publicly available Pincaster class. These read as follows:

* `Pincaster.is_alive?` - returns *true* or *false*, depending on Pincaster server's state
* `Pincaster.shutdown!` - cleanly shut's down Pincaster, so every in-memory-only-data can be persited before exit
* `Pincaster.layers` - returns an array of strings representing the available layers (AR class names of indexed models)
* `Pincaster.has_layer(string)` - returns *true* or *false* depending of existance of the given layer
* `Pincaster.add_layer(string)` - adds a layer with given string as name
* `Pincaster.delete_layer!(string)` - deletes the layer with the given name
* `Pincaster.layer(string)` - return a Kingpin layer object that can be used to retrieve some more information about a layer
* `Pincaster.config` - returns a Kingpin config objects that hold's Pincasters config

Interesting layer related methods are:

    layer = Pincaster.layer("FooWithLocation")

* `layer.name` - returns layers name
* `layer.records` - returns the number of records (pin's) in that very layer
* `layer.geo_records` - returns the number of records in that layer having geo data included
* `layer.distance_accuracy` - returns the distance accuracy level
* `layer.type` - returns the layers type (please have a look at the Pincaster doc's here)
* `layer.bounds` - returns the layers bounds

Coming soon
-----------

Kingpin is missing some functionality yet, but this will arrive soon:

- support for rectangle search
- distance integration into every returned AR record at retrieval time
- automated Raketask for index creation
- tests

Authors
-------

Kingpin was written by:

[Jan Roesner](http://railspotting.de) mailto: <jan@roesner.it>

for use at [Friendticker](http://www.friendticker.de)


Thanks
------

* Frank Denis for his support
* Anke for moral support
* the Friendticker staff

Contributing to Kingpin
-----------------------

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
* Send me a pull request. Bonus points for topic branches.


Copyright
---------

Copyright (c) 2011 Jan Roesner. See LICENSE.txt for further details.
