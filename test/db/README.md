Setup dbrow_test database
=========================

1. in `pgsql`
  1. create database dbrow_test;
  1. create user dbrow_test superuser password 'derp';
1. in cf admin, create datasource `dbrow_test`
1. run migrations, eg.
  * `psql -h localhost -f 001.sql -U dbrow_test dbrow_test`
