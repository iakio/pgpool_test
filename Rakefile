require 'yaml'
require 'rake/testtask'

conf = YAML.load_file('config.yaml')
pgsql_bin = conf['backend'].fetch('bin_path', '/usr/local/pgsql/bin')
initdb_bin = File.join(pgsql_bin, 'initdb')
pg_ctl_bin = File.join(pgsql_bin, 'pg_ctl')

conf['backend']['nodes'].each do |node|
  port = node['port']

  # directory db#{port} (initdb)
  file "db#{port}" do
    sh "#{initdb_bin} --no-locale db#{port}"
    rm "db#{port}/postgresql.conf"
  end

  # file db#{port}/postgresql.conf
  file "db#{port}/postgresql.conf" => [ "db#{port}" ] do
    open("db#{port}/postgresql.conf", "w") do |c|
      pgconfig = conf['backend']['default'].merge(node)
      open("db#{port}/PG_VERSION", "r") do |v|
        short_ver = v.readline.chomp.gsub(/\./, "")
        if short_ver && conf['backend'].has_key?("default#{short_ver}")
          pgconfig = conf['backend']["default#{short_ver}"].merge(pgconfig)
        end
      end
      pgconfig.each do |k, v|
        c.puts "#{k} = #{v}"
      end
    end
  end
  
  # file db#{port}/postmaster.pid (startdb)
  file "db#{port}/postmaster.pid" => [ "db#{port}/postgresql.conf" ] do
    sh "#{pg_ctl_bin} start -D db#{port}"
  end
end

ports = conf['backend']['nodes'].collect { |node| node['port'] }

file "pgpool.conf" => [ 'config.yaml' ] do
  open "pgpool.conf", "w" do |c|
    conf['pgpool'].each do |k, v|
      c.puts "#{k} = #{v}"
    end
    c.puts
    ports.each_with_index do |port, i|
      c.puts "backend_hostname#{i} = ''"
      c.puts "backend_port#{i} = #{port}"
      c.puts "backend_weight#{i} = 1"
    end
  end
end

desc "Start all databases."
task :startdb => ports.map { |port| [ "db#{port}/postmaster.pid" ] }

desc "Stop all databases."
task :stopdb do
  conf['backend']['nodes'].each do |node|
    sh "#{pg_ctl_bin} stop -D db#{node['port']}"
  end
end

Rake::TestTask.new
