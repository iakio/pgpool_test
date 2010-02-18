require 'test/unit'
require File.dirname(__FILE__) + '/helper'

class TestTimestamp < Test::Unit::TestCase
  include Pgpool::TestHelper


  def setup
    @dbname = 'pool_test'
    connection do |c|
      c.query "create table rel1(i int, t timestamp)"
      c.query "create table rel2(i1 int, i2 int, t timestamp)"
    end
  end


  def teardown
    each_backend do |c|
      c.query "drop table rel1" rescue nil
      c.query "drop table rel2" rescue nil
    end
  end


  def test_expand_now
    connection do |c|
      c.query "insert into rel1 values(1, now())"
      c.query "insert into rel1 values(2, current_timestamp)"
      assert_replicated "select * from rel1"
      c.query "update rel1 set t = now() where i = 1"
      assert_replicated "select * from rel1"
    end
  end


  def test_expand_now_after_error
    connection do |c|
      c.query "error" rescue 1
      c.query "insert into rel1 values(1, now())"
      c.query "error" rescue 1
      c.query "insert into rel1 values(2, current_timestamp)"
      assert_replicated "select * from rel1"
    end
  end


  def test_expand_now_with_prepare
    connection do |c|
      c.query "prepare q1(int) as insert into rel1 values($1, now())"
      c.query "execute q1(1)"
      c.query "execute q1(2)"
      assert_replicated "select * from rel1"
      c.query "prepare q2(int) as update rel1 set t = current_timestamp where i = $1"
      c.query "execute q2(1)"
      assert_replicated "select * from rel1"
      c.query "prepare q3 as insert into rel1 values(3, now())"
      c.query "execute q3"
      assert_replicated "select * from rel1"
    end
  end


  def test_expand_now_with_extend_protocol
    connection do |c|
      c.prepare "q1", "insert into rel1 values($1, now())"
      c.exec_prepared "q1", [1]
      c.exec_prepared "q1", [2]
      assert_replicated "select * from rel1"
      c.prepare "q2", "update rel1 set t = current_timestamp where i = $1"
      c.exec_prepared "q1", [2]
      assert_replicated "select * from rel1"
      c.prepare "q3", "insert into rel1 values(3, now())"
      c.exec_prepared "q3"
      assert_replicated "select * from rel1"
    end
  end


  def test_expand_now_unnamed
    connection do |c|
      c.transaction do
        c.prepare "", "insert into rel1 values($1, now())"
        c.exec_prepared "", [1]
        c.exec_prepared "", [2]
        assert_replicated "select * from rel1"
        c.prepare "", "update rel1 set t = current_timestamp where i = $1"
        c.exec_prepared "", [2]
        assert_replicated "select * from rel1"
      end
    end
  end


  def test_expand_now_ex_with_formatopt
    connection do |c|
      c.prepare "q1", "insert into rel2 values($1, $2, now())"
      c.exec_prepared "q1", [
        { :value => "10", :format => 0 },
        { :value => [1234].pack("N"), :format => 1 },
      ]
    end
  end
end
