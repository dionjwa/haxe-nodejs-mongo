package database;

import org.transition9.util.Assert;

import org.transition9.serialization.Serialization;

import js.Node;

import js.node.mongo.Mongo;
import js.node.mongo.MongoPool;
import js.node.mongo.MongoTools;

using Lambda;

using StringTools;

/**
 * Serialization tests
 */
class MongoTest 
{
	public function new() 
	{
	}
	
	@Before
	public function setup (cb :Void->Void) :Void
	{
		cb();
	}
	
	@After
	public function tearDown (cb :Void->Void) :Void
	{
		cb();
	}
	
	@AsyncTest
	public function testMongoSerialization (onTestFinish :Void->Void) :Void
	{
		
		var pool = new MongoPool("127.0.0.1", 27017, "defaultdb", 3);
		pool.connection(function (db :Database) {
			MongoTools.create(pool, Blob, function (err :MongoErr, obj :Blob) {
				if (err != null) trace(Std.string(err));
				Assert.isNotNull(obj);
				
				MongoTools.load(pool, Blob, obj._id, function (err :MongoErr, loaded :Blob) {
					if (err != null) trace(Std.string(err));
					// trace('loaded=' + Std.string(loaded));
					Assert.isNotNull(loaded, "loaded is null");
					
					// MongoTools.find(pool, Blob, "a", 1, function (err :MongoErr, loaded :Blob) {
						// if (err != null) trace(Std.string(err));
						// trace('found with a==1:' + Std.string(loaded));
						
						Assert.isNotNull(loaded, "find loaded is null");	
						
						loaded.a = 4;
						loaded.b = "changed";
						loaded.c = [1, 2, 3];
						loaded.d = ["foo", "bar"];
						loaded.e = [Date.now(), Date.now()];
						
						MongoTools.update(pool, loaded, function (err :MongoErr, done :Bool) {
							if (err != null) trace(Std.string(err));
							// trace('updated from ' + loaded + ', now load again');
							
							MongoTools.load(pool, Blob, loaded._id, function (err :MongoErr, updated :Blob) {
								if (err != null) trace(Std.string(err));
								org.transition9.util.Assert.isTrue(updated.a == loaded.a);
								org.transition9.util.Assert.isTrue(updated.b == loaded.b);
								org.transition9.util.Assert.isTrue(updated.c != null);
								org.transition9.util.Assert.isTrue(updated.c.length == loaded.c.length);
								org.transition9.util.Assert.isTrue(updated.c[0] == loaded.c[0]);
								
								// trace(JSON.stringify(Serialization.classToDoc(loaded)));
								
								org.transition9.util.Assert.isTrue(updated.d != null);
								org.transition9.util.Assert.isTrue(updated.d.length == loaded.d.length);
								org.transition9.util.Assert.isTrue(updated.d[0] == loaded.d[0], "updated.d=" + updated.d + ", loaded.d=" + loaded.d[0]);
								
								org.transition9.util.Assert.isTrue(updated.e != null);
								org.transition9.util.Assert.isTrue(updated.e.length == loaded.e.length);
								
								// trace('updated.e[0]=' + updated.e[0].getTime());
								// trace('loaded.e[0]=' + loaded.e[0].getTime());
								// trace(updated.e[0].getTime() - loaded.e[0].getTime());
								// org.transition9.util.Assert.isTrue(updated.e[0].getTime() == loaded.e[0].getTime(), updated.e[0].getTime() + "==" + updated.e[0].getTime());
								
								// trace('updated loaded=' + Std.string(updated));
								
								// MongoTools.keys(pool, Blob, function (err :MongoErr, keys :Array<Dynamic>) {
								// 	if (err != null) trace(Std.string(err));
									// trace('keys=' + keys);
									onTestFinish();
								// });
							});
						});
					// });
				});
			});
		});
	}
	
	@AsyncTest
	public function testGridfs (onTestFinish :Void->Void) :Void
	{
		var pool = new MongoPool("127.0.0.1", 27017, "defaultdb", 2);
		pool.ready = function () {};//Ignore
		pool.connection(function (db :Database) {
			
			var filePath = "README.md";
			var gridFile = Mongo.newGridStore(db, filePath, "w");
			
			gridFile.writeFile(filePath, function (err :MongoErr, file :GridStore) {
				if (err != null) trace(err);
				onTestFinish();
			});
		});
	}
}
