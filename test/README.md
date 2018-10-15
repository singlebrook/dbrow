Setup dbrow Unit Tests
================

1. Install mxunit submodule: `git submodule update --init`
1. Install commandbox
1. In the 'dbrow/test' directory, run `box server start`

Setup dbrow_test database
-------------------------

1. in `psql`
  1. `create user dbrow_test password 'derp';`
  1. `create database dbrow_test with owner dbrow_test;`
1. run migrations, eg.
  * `psql -h localhost -f test/db/migrate/001.sql -U dbrow_test dbrow_test`
