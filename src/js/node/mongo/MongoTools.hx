package js.node.mongo;

import org.transition9.serialization.Serialization;

import js.node.mongo.Mongo;

import Type;
/**
  * Static functions to get Haxe objects in and out of MongoDB.
  */
class MongoTools
{
	static var COUNTERS = "counters";
	
	/**
	  * Returns the next per class counter.
	  */
	public static function nextId (c :Database, type :Class<Dynamic>, cb :MongoErr->Int->Void) :Void
	{
		var klsName = Type.getClassName(type);
		c.collection(COUNTERS, function (err :MongoErr, collection :Collection) {
			
			if (returnIfError(err, cb)) return;
			
			var options = {};
			Reflect.setField(options, "new", true);
			Reflect.setField(options, "upsert", true);
			Reflect.setField(options, "remove", false);
			
			var doc = {};
			Reflect.setField(doc, "$inc", {next:1});
			
			var sort = [];
			
			collection.findAndModify({_id:klsName}, sort, doc, options, function (err :MongoErr, val :MongoObj) {
				if (returnIfError(err, cb)) return;
				cb(null, val.next);
			});
		});
	}
	
	public static function createIndices (pool :MongoPool, type :Class<Dynamic>) :Void
	{
		var indices :Array<{name:String, filter:Dynamic->Dynamic}> = Reflect.field(type, "_indexOn");
		if (indices == null) return;
		
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (err != null) {trace("err:" + Std.string(err)); return;}
				
				for (index in indices) {
					var query = {};
					Reflect.setField(query, index.name, 1);
					collection.ensureIndex(query);
				}
			});
		});
	}
	
	public static function keys (pool :MongoPool, type :Class<Dynamic>, cb :MongoErr->Array<Dynamic>->Void) :Void
	{
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var keys :Array<String> = [];
				
				var meta :MongoMeta = {skip:0, limit:0, sort:{_id:1}};
				
				collection.find({}, {_id:1}, meta, function (err :MongoErr, cursor :Cursor) {
					cursor.each(function (err :MongoErr, rec :MongoObj) {
						if (returnIfError(err, cb, pool, c)) return;
						if (rec == null) {
							pool.returnConnection(c);
							cb(null, keys);
						} else {
							keys.push(rec._id);
						}
					});
				});
			});
		});
	}
	
	public static function create <T>(pool :MongoPool, type :Class<T>, cb :MongoErr->T->Void) :Void
	{
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var obj = Type.createInstance(type, EMPTY_ARRAY);
				
				var rec :MongoObj = classToDoc(obj);
				
				collection.insert(rec, function (err :MongoErr, inserted :MongoObj) {
					if (returnIfError(err, cb, pool, c)) return;
					
					pool.returnConnection(c);
					Reflect.setField(obj, "_id", rec._id);
					// trace("created " + klsName + ", returning " + obj);
					cb(null, obj);
				});
			});
		});
	}
	
	public static function add <T>(pool :MongoPool, obj :Dynamic, cb :MongoErr->Dynamic->Void) :Void
	{
		var type = Type.getClass(obj);
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var rec :MongoObj = classToDoc(obj);
				
				collection.insert(rec, function (err :MongoErr, inserted :MongoObj) {
					if (returnIfError(err, cb, pool, c)) return;
					
					pool.returnConnection(c);
					Reflect.setField(obj, "_id", rec._id);	
					cb(null, rec._id);
				});
			});
		});
	}
	
	public static function update (pool :MongoPool, obj :Dynamic, cb :MongoErr->Bool->Void) :Void
	{
		var type = Type.getClass(obj);
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var rec :MongoObj = classToDoc(obj);
				
				collection.save(rec, EMPTY_OPTIONS, function (err :MongoErr, updated :MongoObj) {
					if (returnIfError(err, cb, pool, c)) return;
				
					pool.returnConnection(c);
					cb(null, true);
				});
			});
		});
	}
	
	public static function remove (pool :MongoPool, type :Class<Dynamic>, id :Dynamic, cb :MongoErr->Bool->Void) :Void
	{
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				collection.remove({_id:id}, null, function () :Void {
					pool.returnConnection(c);
					cb(null, true);	
				});
			});
		});
	}
	
	public static function load<T>(pool :MongoPool, type :Class<T>, id :Dynamic, cb :MongoErr->T->Void) :Void
	{
		//If the id is a String with length 24, convert to native ObjectID
		switch(Type.typeof(id)) {
			case TClass(c):
				if (c == String && id.length == 24) {
					id = Mongo.createObjectIDFromHexString(id);
				}
			default://Nothing, keep the id
		}
		
		findInternal(pool, type, {_id:id}, cb);
	}
	
	public static function find<T>(pool :MongoPool, type :Class<T>, field :String, val :Dynamic, cb :MongoErr->T->Void) :Void
	{
		var query = {};
		Reflect.setField(query, field, val);
		findInternal(pool, type, query, cb);
	}
	
	public static function findAllKeys (pool :MongoPool, type :Class<Dynamic>, field :String, val :Dynamic, cb :MongoErr->Array<Int>->Void) :Void
	{
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var keys :Array<Int> = [];
				
				var meta :MongoMeta = {skip:0, limit:0, sort:null};
				
				var query = {};
				Reflect.setField(query, field, val);
		
				collection.find(query, {_id:1}, meta, function (err :MongoErr, cursor :Cursor) {
					cursor.each(function (err :MongoErr, rec :MongoObj) {
						if (returnIfError(err, cb, pool, c)) return;
						if (rec == null) {
							pool.returnConnection(c);
							cb(null, keys);
						} else {
							keys.push(rec._id);
						}
					});
				});
			});
		});
	}
	
	public static function findAll<T>(pool :MongoPool, type :Class<T>, field :String, val :Dynamic, limit :Int, sort :Bool, ascending :Bool, cb :MongoErr->Array<T>->Void) :Void
	{
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
				
				var objs :Array<T> = [];
				
				var meta :MongoMeta = {skip:0, limit:limit, sort:null};
				if (sort) {
					meta.sort = {};
					Reflect.setField(meta.sort, field, ascending ? 1 : -1);
				}
				
				var query = {};
				if (field != null) {
					Reflect.setField(query, field, val);
				}
		
				collection.find(query, null, meta, function (err :MongoErr, cursor :Cursor) {
					cursor.each(function (err :MongoErr, rec :MongoObj) {
						if (returnIfError(err, cb, pool, c)) return;
						if (rec == null) {
							pool.returnConnection(c);
							cb(null, objs);
						} else {
							var obj :T = docToClass(rec, type);
							objs.push(obj);
						}
					});
				});
			});
		});
	}
	
	static function findInternal<T>(pool :MongoPool, type :Class<T>, query :Dynamic, cb :MongoErr->T->Void) :Void
	{
		org.transition9.util.Assert.isNotNull(pool, ' pool is null');
		org.transition9.util.Assert.isNotNull(type, ' type is null');
		var klsName = Type.getClassName(type);
		pool.connection(function (c :Database) {
			c.collection(klsName, function (err :MongoErr, collection :Collection) {
				if (returnIfError(err, cb, pool, c)) return;
			
				org.transition9.util.Assert.isNotNull(collection, ' collection is null');
				
				collection.findOne(query, function (err :MongoErr, rec :MongoObj) {
					if (returnIfError(err, cb, pool, c)) return;
					
					pool.returnConnection(c);
					
					if (rec == null) {
						cb(null, null);
					} else {
						var obj :T = docToClass(rec, type);
						cb(null, obj);
					}
				});
			});
		});
	}
	
	inline static function returnIfError(err :MongoErr, cb :MongoErr->Dynamic->Void, ?pool :MongoPool, ?c :Database) :Bool
	{
		if (err != null) {
			if (pool != null && c != null) {
				pool.returnConnection(c);
			}
			cb(err, null);
			return true;
		} else {
			return false;
		}
	}
	
	/**
	  * If the object had a String _id of length 24, convert to a native ObjectID
	  */
	public static function classToDoc (obj :Dynamic) :Dynamic
	{
		var rec :MongoObj = Serialization.classToDoc(obj);
		if (Reflect.field(obj, "_id") != null) {
			switch(Type.typeof(Reflect.field(obj, "_id"))) {
				case TClass(c):
					if (c == String && Reflect.field(obj, "_id").length == 24) {
						Reflect.setField(rec, "_id", Mongo.createObjectIDFromHexString(Reflect.field(obj, "_id")));
					}
				default://Nothing, keep the id
			}
		}
		return rec;
	}
	
	public static function docToClass (rec :Dynamic, cls :Class<Dynamic>) :Dynamic
	{
		org.transition9.util.Assert.isNotNull(rec, ' rec is null ' + haxe.Stack.toString(haxe.Stack.callStack()));
		org.transition9.util.Assert.isNotNull(cls, ' cls is null');
		var obj = Serialization.docToClass(rec, cls);
		org.transition9.util.Assert.isNotNull(obj, ' obj is null');
		Reflect.setField(obj, "_id", Reflect.field(rec, "_id"));
		org.transition9.util.Assert.isNotNull(obj._id, ' obj._id is null');
		return obj;
	}
	
	static var EMPTY_ARRAY :Array<Dynamic> = [];
	static var EMPTY_OPTIONS :Dynamic = {};
}
