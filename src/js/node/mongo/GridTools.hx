package js.node.mongo;

import js.Node;

import js.node.mongo.Mongo;
import js.node.mongo.MongoPool;

import org.transition9.async.AsyncTools;

class GridTools
{
	public static function writeGridFileToDisk (pool :MongoPool, dbFileName :String, fileSystemPath :String, cb :Dynamic->Bool->Void) :Void
	{
		pool.connection(function (db :Database) {
			Mongo.grid.readlines(db, dbFileName, "\n", null, function (err, lines :Array<String>) {
				if (AsyncTools.returnIfError(err, cb)) return;
				pool.returnConnection(db);
				Node.fs.writeFile(fileSystemPath, lines.join(""), NodeC.UTF8, function (err) {
					if (AsyncTools.returnIfError(err, cb)) return;	
					cb(null, true);
				});
			});
		});
	}
}
