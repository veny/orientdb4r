  $: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  require 'orientdb4r'

  CLASS = 'myclass'

  client = Orientdb4r.client  # equivalent for :host => 'localhost', :port => 2480, :ssl => false

  client.connect :database => 'temp', :user => 'admin', :password => 'admin'

  unless client.class_exists? CLASS
    client.create_class(CLASS) do |c|
      c.property 'prop1', :integer, :notnull => true, :min => 1, :max => 99
      c.property 'prop2', :string, :mandatory => true
      c.link     'users', :linkset, 'OUser' # by default: :mandatory => false, :notnull => false
    end
  end

  admin = client.query("SELECT FROM OUser WHERE name = 'admin'")[0]
  1.upto(5) do |i|
    # insert link to admin only to first two
    client.command "INSERT INTO #{CLASS} (prop1, prop2, users) VALUES (#{i}, 'text#{i}', [#{admin['@rid'] if i<3}])"
  end

  puts client.query "SELECT FROM #{CLASS}"
  #>

  puts client.query "SELECT count(*) FROM #{CLASS}"
  #>

  puts client.query "SELECT max(prop1) FROM #{CLASS}"
  #>

  puts client.query "TRAVERSE any() FROM (SELECT FROM #{CLASS} WHERE prop1 = 1)"
  #>


  client.drop_class CLASS
  client.disconnect
