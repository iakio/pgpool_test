require 'test/unit'
require File.dirname(__FILE__) + '/helper'

class TestTimestampDefault < Test::Unit::TestCase
  include Pgpool::TestHelper

  def setup
    @dbname = 'pool_test'
    connection do |c|
      c.query "create table tsdef1(i int, t timestamp default now(), d date default current_timestamp)"
    end
  end

  def teardown
    each_backend do |c|
      c.query "drop table tsdef1" rescue nil
    end
  end

  def test_expand_default
    connection do |c|
      c.query "insert into tsdef1 values(1)"
      c.query "insert into tsdef1 values(2)"
      assert_replicated "select * from tsdef1 order by i"
      c.query "update tsdef1 set t = default where i = 1"
      assert_replicated "select * from tsdef1 order by i"
    end
  end

  def test_expand_default_after_error
    connection do |c|
      c.query "error" rescue 1
      c.query "insert into tsdef1 values(1)"
      c.query "error" rescue 1
      c.query "insert into tsdef1 values(2)"
      assert_replicated "select * from tsdef1"

      c.transaction do
        c.query "error" rescue 1
        c.query "insert into tsdef1 values(1)" rescue 1
      end
      assert_replicated "select * from tsdef1"
    end
  end

  def test_expand_default_with_prepare
    connection do |c|
      c.query "prepare q1(int) as insert into tsdef1 values($1)"
      c.query "execute q1(1)"
      c.query "execute q1(2)"
      assert_replicated "select * from tsdef1"
      c.query "prepare q2(int) as update tsdef1 set t = default where i = $1"
      c.query "execute q2(2)"
      assert_replicated "select * from tsdef1"
    end
  end

  def test_expand_default_with_extend_protocol
    connection do |c|
      c.prepare "q1", "insert into tsdef1 values($1)"
      c.exec_prepared "q1", [1]
      c.exec_prepared "q1", [2]
      assert_replicated "select * from tsdef1"
      c.prepare "q2", "update tsdef1 set t = default, d = default where i = $1"
      c.exec_prepared "q1", [2]
      assert_replicated "select * from tsdef1"
    end
  end

  def test_expand_default_with_unnamed
    connection do |c|
      c.transaction do
        c.prepare "", "insert into tsdef1 values($1)"
        c.exec_prepared "", [1]
        c.exec_prepared "", [2]
        assert_replicated "select * from tsdef1"
        c.prepare "", "update tsdef1 set t = default, d = default where i = $1"
        c.exec_prepared "", [2]
        assert_replicated "select * from tsdef1"
      end
    end
  end
end
