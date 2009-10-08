require 'lib/model'

DB = Sequel.sqlite

describe 'Sequel::Model.create_schema' do
  it 'should create the table with the schema if no table exists' do
    class Foo < Sequel::Model; end

    Foo.table_exists?.should.equal false

    class Foo < Sequel::Model
      create_schema do
        primary_key :id
      end
    end

    Foo.table_exists?.should.equal true
    Foo.primary_key.should.equal :id
  end

  it 'should implicitly add a timestamped column called updated' do
    class Bar < Sequel::Model
      create_schema do
        primary_key :id
      end
    end

    Bar.columns.should.be.a lambda {|c| c.include?(:updated)}
    Bar.new.save.updated.class.should.equal Time
  end

  it 'should not add the updated column if requested' do
    class Baz < Sequel::Model
      create_schema :no_timestamp do
        primary_key :id
      end
    end

    Baz.columns.should.be.a lambda {|c| !c.include?(:updated)}
  end
end
