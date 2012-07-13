require 'study_case'

# This class represents model and data for Technical Feasibility Study.
# See here for more info:
# https://github.com/veny/orientdb4r/wiki/Technical-Feasibility
class TechnicalFeasibility < FStudy::Case

#  def db; 'perf'; end

  def drop
    client.drop_class 'Community'
    puts "droped class: Community"
    client.drop_class 'OrgUnit'
    puts "droped class: OrgUnit"
    client.drop_class 'User'
    puts "droped class: User"
  end
  def model
    drop
    # OrgUnit
    client.create_class 'OrgUnit' do |c|
      c.property 'name', :string, :mandatory => true
      c.property 'location', :string
      c.link 'descendants', :linkset, 'OrgUnit'
      # TODO rdbms_id
    end
    puts "created class: OrgUnit"
    # Community
    client.create_class 'Community' do |c|
      c.property 'name', :string, :mandatory => true
      # TODO rdbms_id
    end
    puts "created class: Community"
    # User
    client.create_class 'User' do |c|
      c.property 'username', :string, :mandatory => true
      c.property 'email', :string, :mandatory => true
      c.property 'firstname', :string, :mandatory => true
      c.property 'surname', :string, :mandatory => true
      # TODO rdbms_id, roles
      c.link     'unit', :link, 'OrgUnit', :mandatory => true
      c.link     'communities', :linkset, 'Community'
    end
    puts "created class: User"
    client.create_class 'Content' do |c|
      c.property 'title', :string, :mandatory => true
      # TODO rdbms_id
      c.link     'unit', :link, 'OrgUnit', :mandatory => true
      c.link     'communities', :linkset, 'Community'
    end
    puts "created class: Content"
  end
  def del
    client.command 'DELETE FROM User'
  end
  def data
    insert_communities
    insert_org_units
  end

  def count
    puts client.query 'SELECT count(*) FROM User'
  end


  private

    def insert_communities
      communities = [
        { '@class' => 'Community', :name => 'Pianists' },
        { '@class' => 'Community', :name => 'Violinists' },
        { '@class' => 'Community', :name => 'Dog fanciers' },
        { '@class' => 'Community', :name => 'Cat fanciers' },
        { '@class' => 'Community', :name => 'Soccer fans' },
        { '@class' => 'Community', :name => 'Ski fans' },
        { '@class' => 'Community', :name => 'Basket fans' },
        { '@class' => 'Community', :name => 'Gourmets' },
        { '@class' => 'Community', :name => 'Scifi reader' },
        { '@class' => 'Community', :name => 'Comic reader' }
      ]
      rids = []
      communities.each do |c|
        c['@class'] = 'Community'
        rids << client.create_document(c)
      end
      puts "created communities: #{rids}"
      rids
    end

    def insert_org_units
      root = { :name => 'Big Company', :descendants => [
          { :name => 'Automotive', :descendants => [
              { :name => 'Sales' },
              { :name => 'Marketing' },
              { :name => 'Design' }
            ]
          }, # Automotive
          { :name => 'Research', :descendants => [
              { :name => 'Scientist' },
              { :name => 'Spies' }
            ]
          }, # Research
          { :name => 'Company Infrastructure', :descendants => [
              { :name => 'Accounting' },
              { :name => 'Human Resources' , :descendants => [ { :name => 'Recruitment' } ] }
            ]
          } # Company Infrastructure
        ]
      } # Big Company
      insert_org_unit_helper(root)
    end

    def insert_org_unit_helper(unit)
        unit['@class'] = 'OrgUnit'
        descendants = []
        if unit.include? :descendants
          unit[:descendants].each do |d|
            descendants << insert_org_unit_helper(d)
          end
        end
        unit[:descendants] = descendants unless descendants.empty?
        client.create_document(unit)
    end

end

c = TechnicalFeasibility.new
c.run
puts 'OK'
