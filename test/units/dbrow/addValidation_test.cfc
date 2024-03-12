<cfcomponent extends="dbrow.test.units.abstract_testcase">
<cfscript>

public void function setUp() {
	Super.setUp();
	arthropod = arthropod_factory.create();
}

/* `addValidation` should store function name in `stCustomValidation` -Jared 2013 */
public void function test_should_store_fn_name() {
	arthropod.addValidation(argumentCollection = {
		'propertyName' = 'arthropod_name', 'fn' = 'foobar', 'errorText' = 'derp'
	});
	var actual = arthropod.stCustomValidation['arthropod_name'][1]['fn'];
	assertEquals('foobar', actual);
}

</cfscript>
</cfcomponent>
