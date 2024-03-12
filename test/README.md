Setup dbrow Unit Tests
================

1. Install commandbox
1. Install deps `box install`
1. Install cfconfig `box install commandbox-cfconfig`

Setup dbrow_test database
-------------------------

1. in `psql`
  1. `create user dbrow_test password 'derp';`
  1. `create database dbrow_test with owner dbrow_test;`
1. run migrations, eg.
  * `psql -h localhost -f test/db/migrate/001.sql -U dbrow_test dbrow_test`

Running dbrow Unit Tests
-----------------------

In the root of the repo (i.e. the `dbrow` directory), run one of:

- `box server start` (Uses Lucee 5, per server.json. It is default because it needs no config.)
- `box server start cfengine=lucee@5` (Lucee)
- `box server start cfengine=adobe@2021` (Adobe ColdFusion 2021, see config needs below)

Running on Adobe
----------------
- In order to get robust exception output with newer ACF, you need to install the debugger package: `box cfpm install debugger`
- `box cfpm install postgresql`
- `box cfpm install caching`
