package ;

class Tests
{
	public static function main () :Void
	{
		org.transition9.unit.AsyncTestTools.runTestsOn(cast [
			database.MongoTest,
		]);
	}
}
