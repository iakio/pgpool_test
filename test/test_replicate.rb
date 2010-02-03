require 'test/unit'
require File.dirname(__FILE__) + '/helper'

class TestReplicate < Test::Unit::TestCase
  include Pgpool::TestHelper

  def setup
    @dbname = 'pool_test'
    connection do |c|
      c.query "create sequence t_seq"
      c.query "create view t_v as select nextval('t_seq')"
    end
  end

  def teardown
    each_backend do |c|
      c.query "drop view t_v"
      c.query "drop sequence t_seq"
    end
  end


  # 1. setval('t_seq', 1)
  # 2. Do given queies.
  # 3. Return "nextval('t_seq')" for each backends as Array.
  def _test_replicate(sql)
    sql = [ sql ] unless sql.is_a? Enumerable
    connection do |c|
      c.query "select setval('t_seq', 1, false)"
      sql.each do |q|
        c.query q
      end
    end

    config['backend']['nodes'].map do |node|
      PGconn.open(:port => node['port'], :dbname => @dbname) do |c|
        break c.query("select nextval('t_seq')")[0]
      end
    end
  end

  def assert_replicate(sql)
    res = _test_replicate(sql)
    assert res.all? {|i| i['nextval'] == "2"}
  end

  def assert_not_replicate(sql)
    if pool_status["load_balance_mode"] == '1'
      # I don't know who is master.
      head, *tail = _test_replicate(sql).sort_by {|i| i['nextval']}.reverse
    else
      head, *tail = _test_replicate(sql)
    end
    assert_equal "2", head['nextval']
    tail.each do |t|
      assert_equal "1", t['nextval']
    end
  end

  def test_simpleselect
    connection do |c|

      # simple SELECT
      assert_not_replicate "select * from t_v"

      # SELECT with nextval: replicate
      assert_replicate "select nextval('t_seq')"
    end
  end

  def test_execute
    connection do |c|
      # select only execute. don't replicate
      assert_not_replicate [
        "prepare p1 as select nextval from t_v",
        "execute p1",
      ]
    end
  end
end
