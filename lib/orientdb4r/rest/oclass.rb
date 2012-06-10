module Orientdb4r

  ###
  # This module represent an API to OrientDB's class.
  module OClass

    ###
    # Gets name of the class.
    def name
      get_mandatory_attribute :name
    end

    ###
    # Gets properties of the class.
    def properties
      get_mandatory_attribute :properties
    end

    ###
    # Gets a property with the given name.
    def property(name)
      props = properties.select { |i| i['name'] == name.to_s }
      raise ArgumentError, "unknown property, name=#{name}" if props.empty?
      raise ArgumentError, "too many properties found, name=#{name}" if props.size > 1 # just to be sure
      props[0]
    end

    ###
    # Gets the super-class.
    def super_class
      get_mandatory_attribute :superClass
    end

    ###
    # Gets clusters of the class.
    def clusters
      get_mandatory_attribute :clusters
    end

    ###
    # Gets the default cluster.
    def default_cluster
      get_mandatory_attribute :defaultCluster
    end

    #------------------------------------------------------------------- Helpers

    ###
    # Gets an attribute value that has to be presented.
    def get_mandatory_attribute(name)
      key = name.to_s
      raise ArgumentError "unknown attribute, name=#{key}" unless self.include? key
      self[key]
    end

  end

end
