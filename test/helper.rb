require 'rubygems'
require 'yaml'
require 'pg'

module Pgpool
  module TestHelper


    def config
      @config ||= YAML.load_file('config.yaml')
    end


    def port
      @port ||= config['pgpool']['config']['port']
    end


    def connection
      PGconn.open(:port => port, :dbname => @dbname) do |c|
        yield c
      end
    end


    def each_backend
      config['backend']['nodes'].each do |node|
        PGconn.open(:port => node['port'], :dbname => @dbname) do |c|
          yield c
        end
      end
    end


    def pool_status
      @pool_status ||= connection do |c|
        res = c.query "show pool_status"
        break Hash[ res.map {|r| [r["item"], r["value"]]} ]
      end
    end


    def assert_replicated(sql, message="")
      results = config['backend']['nodes'].map do |node|
        PGconn.open(:port => node['port'], :dbname => @dbname) do |c|
          break [node['port'], c.query(sql).to_a]
        end
      end
      head, *tail = results
      tail.each do |t|
        msg = build_message(
          message, "(?)<?> <> \n(?)<?>\nquery is <#{sql}>", 
          head[0], head[1], t[0], t[1])
        assert_block(msg) { head[1] == t[1] }
      end
    end
  end
end
