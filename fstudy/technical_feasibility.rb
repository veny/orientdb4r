require 'study_case'

# This class represents model and data for Technical Feasibility Study.
# See here for more info:
# https://github.com/veny/orientdb4r/wiki/Technical-Feasibility
class TechnicalFeasibility < FStudy::Case

  def db; 'perf'; end

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
    communities = insert_communities
    units = insert_org_units
    users = insert_users(10000, units, communities)
    insert_contacts(users, 7) # max pro user => ~ coeficient 4.0 pro user
    contents = insert_contents(users, communities, 1.0) # coeficient pro user
    insert_activities(users, communities, contents, 100) # coeficient pro user
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

      start = Time.now
      communities.each do |c|
        c['@class'] = 'Community'
        c[:rid] = client.create_document(c)
      end
      puts "Created Communities: #{communities.size}, time = #{Time.now - start} [s]"
      communities
    end

    def insert_org_units
      units = [
          { :name => 'BigCompany', :descendants => [ 'Automotive', 'Research', 'Infrastructure' ] },
          { :name => 'Automotive', :descendants => [ 'Sales', 'Marketing', 'Design' ] },
          { :name => 'Sales' },
          { :name => 'Marketing' },
          { :name => 'Design' },
          { :name => 'Research', :descendants => [ 'Scientist', 'Spies' ] },
          { :name => 'Scientist' },
          { :name => 'Spies' },
          { :name => 'Infrastructure', :descendants => [ 'Accounting', 'HumanResources' ] },
          { :name => 'Accounting' },
          { :name => 'HumanResources' , :descendants => [ 'Recruitment' ] },
          { :name => 'Recruitment' }
      ]

      start = Time.now
      units.each { |unit| insert_org_unit_helper(unit, units) }
      puts "Created OrgUnits: #{units.size}, time = #{Time.now - start} [s]"
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

    def insert_users(count, units, communities)
      start = Time.now
      users = []
      1.upto(count) do
        firstname = dg.word
        surname = dg.word
        username =  "#{firstname}.#{surname}"
        # random distribution of Units (1) & Communities (0..3)
        unit = units[rand(units.size)]
        comms = []
        0.upto(rand(4)) { |i| comms << communities[rand(communities.size)][:rid] if i > 0 }

        user = { '@class' => 'User', \
                 :username => username, \
                 :firstname => firstname.capitalize, \
                 :surname => surname.capitalize, \
                 :unit => unit[:rid], \
                 :communities => comms }
        rid = client.create_document(user)
        user[:rid] = rid
        users << user
      end
      puts "Created Users: #{users.size}, time = #{Time.now - start} [s]"
      users
    end

    def insert_contacts(users, max_contacts)
      start = Time.now
      count = 0
      types = [:friend, :family, :coworker, :enemy]
      0.upto(users.size - 1) do |i|
        a = users[i]
        0.upto(rand(max_contacts)) do
          b = users[rand(users.size)]
          client.create_document({'@class' => 'Contact', :a => a[:rid], :b => b[:rid], :type => rand(types.size)})
          count += 1
        end
      end
      puts "Created Contacts: #{count}, time = #{Time.now - start} [s]"
    end

    def insert_contents(users, communities, user_coef = 1.0)
      start = Time.now
      contents = []
      classes = [['Article', 'body'], ['Gallery', 'description'], ['Term', 'topic']]
      limit = (users.size * user_coef).to_i

      1.upto(limit) do
        clazz = classes[rand(classes.size)]
        content = {'@class' => clazz[0], :title => "#{dg.word} #{dg.word}", clazz[1] => dg.word}
        # random distribution of Users (1) & Communities (0..3)
        content[:author] = users[rand(users.size)][:rid]
        comms = []
        0.upto(rand(4)) { |i| comms << communities[rand(communities.size)][:rid] if i > 0 }
        content[:communities] = comms

        rid = client.create_document(content)
        content[:rid] = rid
        contents << content
      end
      puts "Created ContentTypes: #{contents.size}, time = #{Time.now - start} [s]"
      contents
    end

    def insert_activities(users, communities, contents, user_coef)
      start = Time.now
      types = [:login, :logout, :likeit, :rated, :saw, :commented]
      limit = users.size * user_coef
      1.upto(limit) do |i|
        puts "... #{i}" if 0 == i % 100000
        type = rand(types.size)
        activity = { '@class' => 'Activity', :type => type, :stamp => (Time.now.to_i - rand(3600*23*30)) }
        # random distribution of Users (1) & the same communities as user
        user = users[rand(users.size)]
        activity[:source] = user[:rid]
        activity[:communities] = user[:communities]
        # content
        content = (types[type] == :login or types[type] == :logout) ? nil : contents[rand(contents.size)]
        activity[content['@class'].downcase] = content[:rid] unless content.nil?

        client.create_document(activity)
      end
      puts "Created Activities: #{limit}, time = #{Time.now - start} [s]"
    end

    def classes_definition
      # TODO rdbms_id
      [
        { :class => 'OrgUnit', :properties => [
            { :property => 'name', :type => :string, :mandatory => true },
            # TODO domain
            { :property => 'descendants',  :type => :linkset, :linked_class => 'OrgUnit' }]},
        { :class => 'Community', :properties => [
            { :property => 'name', :type => :string, :mandatory => true }]},
        { :class => 'User', :properties => [
            { :property => 'username', :type => :string, :mandatory => true },
            { :property => 'firstname', :type => :string, :mandatory => true },
            { :property => 'surname', :type => :string, :mandatory => true },
            # TODO roles
            { :property => 'unit',  :type => :link, :linked_class => 'OrgUnit', :mandatory => true },
            { :property => 'communities',  :type => :linkset, :linked_class => 'Community' }]},
        { :class => 'Contact', :properties => [
            { :property => 'type', :type => :integer, :mandatory => true },
            { :property => 'a',  :type => :link, :linked_class => 'User', :mandatory => true },
            { :property => 'b',  :type => :link, :linked_class => 'User', :mandatory => true }]},
        { :class => 'Content', :properties => [
            { :property => 'title', :type => :string, :mandatory => true },
            { :property => 'author',  :type => :link, :linked_class => 'User', :mandatory => true },
            { :property => 'accessible_in', :type => :linkset, :linked_class => 'Community' }]},
        { :class => 'Article', :extends => 'Content', :properties => [
            { :property => 'body', :type => :string, :mandatory => true }]},
        { :class => 'Gallery', :extends => 'Content', :properties => [
            { :property => 'description', :type => :string, :mandatory => true }]},
        { :class => 'Term', :extends => 'Content', :properties => [
            { :property => 'topic', :type => :string, :mandatory => true }]},
        { :class => 'Activity', :properties => [
            { :property => 'type', :type => :integer, :mandatory => true },
            { :property => 'stamp', :type => :integer, :mandatory => true },
            { :property => 'source',  :type => :link, :linked_class => 'User', :mandatory => true },
            { :property => 'communities', :type => :linkset, :linked_class => 'Community' }]}
      ]
    end

end

c = TechnicalFeasibility.new
c.run
puts 'OK'
