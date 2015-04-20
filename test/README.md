Setup dbrow Unit Tests
================

1. In apache vhosts, add something like this:

        <VirtualHost *:80>
          ServerName dbrow.localhost
          DocumentRoot /Users/jared/git/singlebrook/dbrow/test
          Include /private/etc/apache2/extra/cf9.conf
        </VirtualHost>

1. In CF Admin, add a mapping:
  1. Map `/dbrow` to `/Users/jared/git/singlebrook/dbrow`, or wherever. (This is not necessary in Railo/Lucee. I'm not sure why its necessary in CF because the mapping is defined in the Application.cfc.)

Setup dbrow_test database
-------------------------

1. in `psql`
  1. `create database dbrow_test`
  1. `create user dbrow_test superuser password 'derp'`
1. in cf admin, create datasource `dbrow_test`
1. run migrations, eg.
  * `psql -h localhost -f 001.sql -U dbrow_test dbrow_test`
