require 'orientdb4r'

DB = 'temp'

c = Orientdb4r.client
c.connect :database => DB, :user => 'admin', :password => 'admin'
dg = Orientdb4r::Utils::DataGenerator.new


def clear(conn)
  conn.drop_class 'Community'
  puts "droped class: Community"
  conn.drop_class 'OrgUnit'
  puts "droped class: OrgUnit"
  conn.drop_class 'User'
  puts "droped class: User"
end

if ARGV.include?('--clear')
  clear(c)
end

if ARGV.include?('--schema')
  clear(c)
  # OrgUnit
  c.create_class 'OrgUnit' do |c|
    c.property 'name', :string, :mandatory => true
    c.property 'network', :boolean
    c.link 'descendants', :linkset, 'OrgUnit'
  end
  puts "created class: OrgUnit"
  # Community
  c.create_class 'Community' do |c|
    c.property 'name', :string, :mandatory => true
  end
  puts "created class: Community"
  # User
  c.create_class 'User' do |c|
    c.property 'username', :string, :mandatory => true
    c.property 'name', :string, :mandatory => true
    c.link     'unit', :link, 'OrgUnit', :mandatory => true
    c.link     'communities', :linkset, 'Community'
  end
  puts "created class: User"
end

if ARGV.include?('--data')

  # Organisational Units
  c. command 'DELETE FROM OrgUnit'
  units = []

  comp_rids = []
  auto_rids = []
  auto_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Sales', :network => true })
  auto_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Marketing', :network => true })
  auto_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Design', :network => true })
  comp_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Automotive', :network => true, :descendants => auto_rids })
  #
  research_rids = []
  research_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Scientist', :network => false })
  research_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Spies', :network => false })
  comp_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Research', :network => false, :descendants => research_rids })
  #
  infra_rids = []
  recruit_rid = c.create_document({ '@class' => 'OrgUnit', :name => 'Recruitment', :network => false })
  infra_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Human Resources', :network => false, :descendants => [recruit_rid] })
  infra_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Accounting', :network => false })
  comp_rids << c.create_document({ '@class' => 'OrgUnit', :name => 'Company Infrastructure', :network => false, :descendants => infra_rids })
  #
  units << c.create_document({ '@class' => 'OrgUnit', :name => 'Big Company', :network => false, :descendants => comp_rids })
  units << auto_rids << research_rids << infra_rids << comp_rids
  units.flatten!.uniq!
  puts "created units: #{units}"

  # Communities
  c. command 'DELETE FROM Community'
  communities = []
  communities << c.create_document({ '@class' => 'Community', :name => 'Pianists' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Violinists' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Dog fanciers' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Cat fanciers' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Soccer fans' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Ski fans' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Basket fans' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Gourmets' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Scifi reader' })
  communities << c.create_document({ '@class' => 'Community', :name => 'Comic reader' })
  puts "created communities: #{communities}"

  # Users
  c. command 'DELETE FROM User'
  1.upto(1000) do
    first_name = dg.word.capitalize
    surname = dg.word.capitalize
    # random distribution of Units (1) & Communities (0..3)
    unit = units[rand(units.size)]
    comms = []
    0.upto(rand(4)) { |i| comms << communities[rand(communities.size)] if i > 0 }

    c.create_document({ '@class' => 'User', \
                        :username => "#{first_name.downcase}.#{surname.downcase}", \
                        :name => "#{first_name.capitalize} #{surname.capitalize}", \
                        :unit => unit, \
                        :communities => comms })
  end

end

# FIND REFERENCES #6:5 [OrgUnit]  # get parent

# TRAVERSE descendants FROM #6:10 WHERE $depth < 2  # get first level of descendants
# SELECT FROM (TRAVERSE descendants FROM #6:10 WHERE $depth < 2) WHERE $depth > 0  # eliminate root of query
# SELECT FROM orgunit WHERE any() traverse(0,10) (name = 'Recruitment')  # get ancestors
