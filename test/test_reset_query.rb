require 'test/unit'
require File.dirname(__FILE__) + '/helper'

class TestResetQuery < Test::Unit::TestCase
  include Pgpool::TestHelper

  def setup
    @dbname = 'pool_test'
  end


  def test_autodeallocate
    assert_nothing_raised do
      connection do |c|
        s1 = c.prepare("s1", "select 1")
        s2 = c.prepare("s2", "select 2")
        s3 = c.prepare("s3", "select 3")
        s4 = c.prepare("s4", "select 4")
      end

      connection do |c|
        s1 = c.prepare("s1", "select 10")
        s2 = c.prepare("s2", "select 20")
        s3 = c.prepare("s3", "select 30")
        s4 = c.prepare("s4", "select 40")
      end
    end
  end


  def test_deallocate
    assert_nothing_raised do
      connection do |c|
        s1 = c.prepare("s1", "select 1")
        s2 = c.prepare("s2", "select 2")
        c.query "deallocate s1"
      end

      connection do |c|
        s1 = c.prepare("s1", "select 1")
        s2 = c.prepare("s2", "select 2")
        c.query "deallocate s2"
      end
    end
  end
end
