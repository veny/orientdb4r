require 'study_case'

# This class represents model and data for Technical Feasibility Study.
# See here for more info:
# https://github.com/veny/orientdb4r/wiki/Technical-Feasibility
class TechnicalFeasibility < FStudy::Case

#  def db; 'perf'; end

  # Dropes the document model.
  def drop
    classes_definition.reverse.each do |clazz|
      client.drop_class clazz[:class]
      puts "droped class: #{clazz[:class]}"
    end
  end

  # Creates the document model.
  def model
    drop
    classes_definition.each do |clazz|
      class_name = clazz.delete :class
      client.create_class(class_name, clazz)
      puts "created class: #{class_name}"
    end
  end

  # Deletes data.
  def del
    classes_definition.each do |clazz|
      client.command "DELETE FROM #{clazz[:class]}"
      puts "deleted from class: #{clazz[:class]}"
    end
  end

  # Prepares data.
  def data
    comm = insert_communities
    units = insert_org_units
puts units
  end

  def count
    puts client.query 'SELECT count(*) FROM User'
  end


  private

    def insert_communities
      communities = [
        { :name => 'Pianists' },
        { :name => 'Violinists' },
        { :name => 'Dog fanciers' },
        { :name => 'Cat fanciers' },
        { :name => 'Soccer fans' },
        { :name => 'Ski fans' },
        { :name => 'Basket fans' },
        { :name => 'Gourmets' },
        { :name => 'Scifi reader' },
        { :name => 'Comic reader' }
      ]
      communities.each do |c|
        c['@class'] = 'Community'
        c[:rid] = client.create_document(c)
      end
      puts "Created communities: #{communities.size}"
      communities
    end

    def insert_org_units
      units = [
          { :name => 'Big Company', :descendants => [ 'Automotive', 'Research', 'Company Infrastructure' ] },
          { :name => 'Automotive', :descendants => [ 'Sales', 'Marketing', 'Design' ] },
          { :name => 'Sales' },
          { :name => 'Marketing' },
          { :name => 'Design' },
          { :name => 'Research', :descendants => [ 'Scientist', 'Spies' ] },
          { :name => 'Scientist' },
          { :name => 'Spies' },
          { :name => 'Company Infrastructure', :descendants => [ 'Accounting', 'Human Resources' ] },
          { :name => 'Accounting' },
          { :name => 'Human Resources' , :descendants => [ 'Recruitment' ] },
          { :name => 'Recruitment' }
      ]
      units.each { |unit| insert_org_unit_helper(unit, units) }
      units
    end
    def insert_org_unit_helper(unit, all)
        return if unit.include? :rid

        if unit.include? :descendants
          # recursion
          unit[:descendants].each do |desc_name|
            next_unit = all.select { |u| u if u[:name] == desc_name }[0]
            insert_org_unit_helper(next_unit, all) unless next_unit.include? :rid
          end
        end

        cloned = unit.clone
        cloned['@class'] = 'OrgUnit'
        cloned.delete :descendants

        if unit.include? :descendants
          descendants = []
          unit[:descendants].each do |name|
            descendants << all.select { |ou| ou if ou[:name] == name }[0][:rid]
          end
          cloned[:descendants] = descendants
        end

        rid = client.create_document(cloned)
        unit[:rid] = rid
    end

    def insert_users(units, communities)
      1.upto(10) do
        firstname = dg.word
        surname = dg.word
        username =  "#{firstname}.#{surname}"
        # random distribution of Units (1) & Communities (0..3)
        unit = units[rand(units.size)]
        comms = []
        0.upto(rand(4)) { |i| comms << communities[rand(communities.size)] if i > 0 }

        c.create_document({ '@class' => 'User', \
                            :username => username, \
                            :email => 'xx',\
                            :firstname => firstname.capitalize, \
                            :surname => surname.capitalize, \
                            :unit => unit[:rid], \
                            :communities => comms })
      end
    end

    def classes_definition
      # TODO rdbms_id
      [
        { :class => 'OrgUnit', :properties => [
          { :property => 'name', :type => :string, :mandatory => true },
          { :property => 'domain', :type => :string },
          { :property => 'descendants',  :type => :linkset, :linked_class => 'OrgUnit' }]},
        { :class => 'Community', :properties => [
            { :property => 'name', :type => :string, :mandatory => true }]},
        { :class => 'User', :properties => [
            { :property => 'email', :type => :string, :mandatory => true },
            { :property => 'firstname', :type => :string, :mandatory => true },
            { :property => 'surname', :type => :string, :mandatory => true },
            { :property => 'unit',  :type => :link, :linked_class => 'OrgUnit', :mandatory => true },
            { :property => 'communities',  :type => :linkset, :linked_class => 'Community' }]},
        { :class => 'Content', :properties => [
            { :property => 'title', :type => :string, :mandatory => true },
            { :property => 'author',  :type => :link, :linked_class => 'User', :mandatory => true },
            { :property => 'accessible_in',  :type => :linkset, :linked_class => 'Community' }]},
        { :class => 'Article', :extends => 'Content', :properties => [
            { :property => 'body', :type => :string, :mandatory => true }]},
        { :class => 'Gallery', :extends => 'Content', :properties => [
            { :property => 'description', :type => :string, :mandatory => true }]},
        { :class => 'Term', :extends => 'Content', :properties => [
            { :property => 'from', :type => :string, :mandatory => true },
            { :property => 'to', :type => :string, :mandatory => true }]}
      ]
    end

end

c = TechnicalFeasibility.new
c.run
puts 'OK'
