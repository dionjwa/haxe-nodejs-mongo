package ;

import utest.Assert;
import utest.Runner;
import utest.ui.Report;

class UTests
{
	public static function main () :Void
	{
		var runner = new Runner();
		// runner.addCase(new database.RedisDatabaseManagerTest());
		runner.addCase(new database.MongoDatabaseManagerTest());
		runner.addCase(new tournament.TournamentTest());
		Report.create(runner);
		runner.run();
	}
}
