module Orientdb4r


  ###
  # Extends a Hash produced by JSON.parse.
  module HashExtension

    ###
    # Gets an attribute value that has to be presented.
    def get_mandatory_attribute(name)
      key = name.to_s
      raise ::ArgumentError, "unknown attribute, name=#{key}" unless self.include? key
      self[key]
    end

  end


  ###
  # This module represents API to OrientDB's class.
  module OClass

    ###
    # Gets name of the class.
    def name
      get_mandatory_attribute :name
    end

    ###
    # Gets properties of the class.
    # Returns nil for a class without properties.
    def properties
      self['properties']
    end

    ###
    # Gets a property with the given name.
    def property(name)
      raise ArgumentError, 'no properties defined on class' if properties.nil?
      props = properties.select { |i| i['name'] == name.to_s }
      raise ::ArgumentError, "unknown property, name=#{name}" if props.empty?
      raise ::ArgumentError, "too many properties found, name=#{name}" if props.size > 1 # just to be sure
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

  end


  ###
  # This module represents API to OrientDB's property.
  module Property

    ###
    # Gets name of the property.
    def name
      get_mandatory_attribute :name
    end

    ###
    # Gets type of the property.
    def type
      get_mandatory_attribute :type
    end

    ###
    # Gets the 'mandatory' flag.
    def mandatory
      get_mandatory_attribute :mandatory
    end

    ###
    # Gets the 'notNull' flag.
    def not_null
      get_mandatory_attribute :notNull
    end

    ###
    # Gets the minimal allowed value.
    def min
      self['min']
    end

    ###
    # Gets the maximal allowed value.
    def max
      self['max']
    end

  end


  ###
  # This module represents API to document metadata.
  module DocumentMetadata

    ###
    # Gets the document class.
    def doc_class
      self['@class']
    end

    ###
    # Gets the document ID.
    def doc_rid
      self['@rid'][1..-1]
    end

    ###
    # Gets the document version.
    def doc_version
      self['@version']
    end

    ###
    # Gets the document type.
    def doc_type
      self['@type']
    end

  end

end
