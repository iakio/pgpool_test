pgpool test
===========


Quick Start::

    $ vim config.yaml
    $ rake startdb
    $ rake pgpool.conf
    $ pgpool -f pgpool.conf
    $ createdb -p9999 pool_test
    $ rake test
    $ pgpool -f pgpool.conf stop
    $ rake stopdb


TODO
--------

* when / how to create database.

* when / how to start pgpool.

* how to test different mode {replicate, loadbalance, parallel}.

* more test (failover, online recovery, etc).
