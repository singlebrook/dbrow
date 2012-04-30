<cfcomponent extends="dbrow.test.units.abstract_testcase">

<!---
	Given a propertyname,
	If that propertyname represents a foreign key,
		Then I want to see a dropdown menu of related items
	Else,
		If the property's datatype is "bit"
			Then I want to see YesNoFormat
		Else if the property is a simple varchar,
			Then I want to see its value, entity-encoded
- Jared 2012-04-30 --->

<cfscript>

  public void function draw_varchar_property_value() {
    var factory = CreateObject('support.factories.arthropod_factory');
    var arthropod = factory.create();
		var nasty_string = '<script type="text/javascript">alert("gotcha");</script>';
		arthropod.arthropod_name = nasty_string;
		var expected = HTMLEditFormat(nasty_string);
		var actual = arthropod.drawPropertyValue('arthropod_name');
    assertEquals(expected, actual);
  }

</cfscript>
</cfcomponent>
