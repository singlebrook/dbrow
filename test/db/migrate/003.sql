CREATE EXTENSION IF NOT EXISTS citext;

create table tblTestCIText (
  testCITextID serial primary key,
  test_citext citext
);
