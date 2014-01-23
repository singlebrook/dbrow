component extends="dbrow.test.units.abstract_testcase" {

  public void function setUp() {
    Super.setUp();
    arthropod = arthropod_factory.create("Wasp");
    arthropod2 = CreateObject('arthropod');
  }


  public void function loadBy_is_case_insensitive() {
    assert(arthropod2.loadBy(filterField = 'arthropod_name', filterValue = 'wasp'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);

    assert(arthropod2.loadBy(filterField = 'arthropod_name', filterValue = 'WASP'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);

    assert(arthropod2.loadBy(filterField = 'arthropod_name', filterValue = 'w*sp'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);

    assert(arthropod2.loadBy(filterField = 'arthropod_name', filterValue = 'W*SP'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);
  }

  public void function loadByName_is_case_insensitive() {
    assert(arthropod2.loadByName('wasp'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);

    assert(arthropod2.loadByName('WASP'));
    assertEquals(arthropod.arthropodID, arthropod2.arthropodID);
  }
}