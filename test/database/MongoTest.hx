package database;

import haxe.remoting.NodeRelay;
import js.node.mongo.Mongo;
import js.node.mongo.MongoTools;

// import utest.Assert;

import com.pblabs.util.Assert;

using Lambda;

using StringTools;

import js.Node;
/**
 * Serialization tests
 */
class MongoTest 
{
	public static function main ()
	{
		var pool = new MongoPool("127.0.0.1", 27017, "defaultdb", 3);
		
		pool.connection(function (db :Database) {
			trace('db=' + db);
			
			MongoTools.create(pool, DBStore, function (err :MongoErr, obj :DBStore) {
				if (err != null) trace(Std.string(err));
				Assert.isNotNull(obj);
				trace('obj=' + Std.string(obj));
				
				MongoTools.load(pool, DBStore, obj._id, function (err :MongoErr, loaded :DBStore) {
					if (err != null) trace(Std.string(err));
					trace('loaded=' + Std.string(loaded));
					Assert.isNotNull(loaded, "loaded is null");
					
					MongoTools.find(pool, DBStore, "a", 1, function (err :MongoErr, loaded :DBStore) {
						if (err != null) trace(Std.string(err));
						trace('found with a==1:' + Std.string(loaded));
						
						Assert.isNotNull(loaded, "find loaded is null");	
						
						loaded.b = "changed";
						
						MongoTools.update(pool, loaded, function (err :MongoErr, done :Bool) {
							if (err != null) trace(Std.string(err));
							trace('updated, now load again');
							
							MongoTools.load(pool, DBStore, loaded._id, function (err :MongoErr, updated :DBStore) {
								if (err != null) trace(Std.string(err));
								trace('updated loaded=' + Std.string(updated));
								
								MongoTools.keys(pool, DBStore, function (err :MongoErr, keys :Array<Dynamic>) {
									if (err != null) trace(Std.string(err));
									trace('keys=' + keys);
								});
							});
						});
					});
				});
			});
			
			
			
			
			// db.collection("test", function (err :MongoErr, collection :Collection) {
			// 	var obj :MongoObj = {};
			// 	Reflect.setField(obj, "foo", "blah");
			// 	collection.insert(obj, function (err :MongoErr, inserted :MongoObj) {
			// 		trace('inserted=' + Std.string(inserted));
					
			// 		pool.returnConnection(db);
					 
					
			// 	});
			// });
		});
	}
	
	
	public function new() 
	{
	}
	
	@BeforeClass
	public function beforeClass():Void
	{
	}
	
	@AfterClass
	public function afterClass():Void
	{
	}
	
	@Before
	public function setup():Void
	{
	}
	
	@After
	public function tearDown():Void
	{
	}
}

