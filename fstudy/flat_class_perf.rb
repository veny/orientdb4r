require 'study_case'

# This class tests performance on a simple flat class.
class FlatClassPerf < FStudy::Case

  def db; 'perf'; end

  def drop
    client.drop_class 'User'
  end
  def model
    drop
    client.create_class 'User' do |c|
      c.property 'username', :string, :mandatory => true
      c.property 'name', :string, :mandatory => true
      c.property 'admin', :boolean
    end
  end
  def del
    client.command 'DELETE FROM User'
  end
  def data
    1.upto(10000) do |i|
      Orientdb4r::logger.info "...done: #{i}" if 0 == (i % 1000)
      first_name = dg.word
      surname = dg.word
      begin
        client.create_document({ '@class' => 'User', \
                          :username => "#{first_name}.#{surname}", \
                          :name => "#{first_name.capitalize} #{surname.capitalize}", \
                          :admin => (0 == rand(2)) })
      rescue Exception => e
        Orientdb4r::logger.error e
      end
    end
  end

  def product
    1.upto(500000) do |i|
      Orientdb4r::logger.info "...done: #{i}" if 0 == (i % 100000)
      name = dg.word
      type = (rand(3) == 0) ? 'a' : 'b'
      begin
        client.command "insert into product cluster #{type} (name,type) values ('#{name}','#{type}')"
#        client.command "insert into product_simple (name,type) values ('#{name}','#{type}')"
      rescue Exception => e
        Orientdb4r::logger.error e
      end
    end
  end

end

c = FlatClassPerf.new
c.run
puts 'OK'
