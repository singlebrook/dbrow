Setup dbrow Unit Tests
================

1. Install mxunit submodule: `git submodule update --init`
1. Install commandbox

Setup dbrow_test database
-------------------------

1. in `psql`
  1. `create user dbrow_test password 'derp';`
  1. `create database dbrow_test with owner dbrow_test;`
1. run migrations, eg.
  * `psql -h localhost -f test/db/migrate/001.sql -U dbrow_test dbrow_test`

Running dbrow Unit Tests
-----------------------

In the 'dbrow/test' directory, run one of:

- `box server start cfengine=lucee@5` (Lucee)
- `box server start cfengine=adobe@11` (Adobe ColdFusion 11, see config needs below)

### Adobe ColdFusion 11 configuration steps
1. Go to CF admin area at /CFIDE/administrator/. Login is admin/commandbox
1. Disable Secure Profile in the Security Section. Without doing this, you
  won't be able to see detailed errors.
1. Enable Robust Exception Information in Debug Output Settings.
1. Add a mapping for /dbrow pointing to the root of the dbrow repo. (I don't
  know why the mapping in Application.cfc doesn't work.)
1. Add a datasource `dbrow_test` pointing to the PostgreSQL database. (I don't
  know why the datasource in Application.cfc doesn't work.)
