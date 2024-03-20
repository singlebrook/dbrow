component extends="dbrow.test.units.abstract_testcase" {

	public void function setUp() {
		Super.setUp();
		subphylum = subphylum_factory.create("Crustacea 1");
		subphylum = subphylum_factory.create("Crustacea 2");
		set = CreateObject('subphylum_set');
	}


	public void function test_getAll_is_case_insensitive() {
		found = set.getAll(filterField = 'subphylum_name', filterValue = 'crustacea 1');
		assertEquals(1, found.recordcount);

		found = set.getAll(filterField = 'subphylum_NAME', filterValue = 'CRUSTACEA *');
		assertEquals(2, found.recordcount);
	}
}
