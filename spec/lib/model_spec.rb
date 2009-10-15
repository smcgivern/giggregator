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
end
