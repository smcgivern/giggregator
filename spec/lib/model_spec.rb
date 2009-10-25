require 'spec/setup'
require 'lib/model'

describe 'Sequel::Model.create_schema' do
  it 'should create the table with the schema if no table exists' do
    class Foo < Sequel::Model; end

    Foo.table_exists?.should.be.false

    class Foo < Sequel::Model
      create_schema do
        primary_key :id
      end
    end

    Foo.table_exists?.should.be.true
    Foo.primary_key.should.equal :id
  end

  it 'should capitalise the required method calls' do
    EMMM = [:eeny, :meeny, :miny, :moe]

    class Bar < Sequel::Model
      create_schema do
        EMMM.each {|w| String(w)}
      end

      capitalize(:eeny, :miny)
    end

    bar = Bar.new(EMMM.inject({}) {|h, w| h.merge w => "#{w} #{w}"})

    bar.eeny.should.equal 'Eeny Eeny'
    bar.meeny.should.equal 'meeny meeny'
    bar.miny.should.equal 'Miny Miny'
    bar.moe.should.equal 'moe moe'
  end
end
