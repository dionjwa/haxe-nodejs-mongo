package js.node.mongo;

/**
	* Externs for using Mongodb directly in Node.js
	*/

import js.Node;

typedef MongoErr = Dynamic;
typedef MongoObj = Dynamic;
typedef MongoQuery=Dynamic;
typedef MongoUpdate=Dynamic;
typedef MongoOptions=Dynamic;

typedef Server = {
	var host :String;
	var port :Int;
	var options :Dynamic;
	var internalMaster :Bool;
	var autoReconnect :Bool;
}

typedef ObjectID = {
	var generationTime :Float;
	var id :String;
	function equals (other :ObjectID) :Bool;
	function toString () :String;
}

typedef Database = {
	function open (cb :MongoErr->Database->Void) :Void;
	function close (cb :Dynamic->Void) :Void;
	function dropDatabase (cb :MongoErr->Dynamic->Void) :Void;
	function collection (name :String, cb :MongoErr->Collection->Void) :Void;
	function createCollection (name :String, cb :MongoErr->Collection->Void) :Void;
	function dropCollection (name :String, cb :MongoErr->Bool->Void) :Void;
	function getStatus() :String;
	function lastStatus(cb :Dynamic->Dynamic->Void) :Void;
}

typedef DBMeta = {
	var colName :String;
	var fld :String;
	var kls :String;
}

typedef MongoMeta = {
	var skip :Int;
	var limit :Int;
	var sort :MongoQuery;
}

typedef Cursor = {
	function each(cb :MongoErr->MongoObj->Void) :Void;
	function nextObject(cb :MongoErr->MongoObj->Void) :Void;
	function toArray(cb :Array<MongoObj>->Void) :Void;
}

typedef Collection = {
	function insert(rec :MongoObj, cb :MongoErr->MongoObj->Void) :Void;
	function insertMany(recs :Array<MongoObj>, cb :MongoErr->Array<MongoObj>->Void) :Void;
	function count(cb :MongoErr->Int->Void) :Void;
	function remove(query :MongoObj, ?options :Dynamic, cb :Void->Void) :Void;
	function find(?query :MongoQuery, options :MongoQuery, ?meta :MongoMeta, cb :MongoErr->Cursor->Void) :Void;
	function findOne(?query :MongoQuery, cb :MongoErr->MongoObj->Void) :Void;
	function findAndModify (query :MongoQuery, sort :MongoObj, doc :MongoObj, options :MongoObj, cb :MongoErr->MongoObj->Void) :Void;
	function drop(cb :MongoErr->Collection) :Void;
	function update(q :MongoQuery, d :MongoObj, options :MongoOptions, cb :MongoErr->MongoObj->Void) :Void;
	function ensureIndex(q :MongoQuery) :Void;
	function save(d :MongoObj, options :MongoOptions, cb :MongoErr->MongoObj->Void) :Void;
}

typedef GridStore = {
	var chunkSize :Int;
	var md5 :String;
	function open (cb :MongoErr->GridStore->Void) :Void;
	function writeFile (file :String, cb :MongoErr->GridStore->Void) :Void;
	function write (data :Dynamic, ?close :Bool, cb :MongoErr->GridStore->Void) :Void;
	function writeBuffer (data :Dynamic, ?close :Bool, cb :MongoErr->GridStore->Void) :Void;
	function close (cb :MongoErr->GridStore->Void) :Void;
	function read (?length :Int, ?buffer :String, cb :MongoErr->String->Void) :Void;
	function readlines (sep :String, cb :MongoErr->Array<String>->Void) :Void;
	
}

//GridFS
typedef GridFileRef=Dynamic;

typedef Grid = {
	function put (data :Dynamic, options :Dynamic, cb :MongoErr->GridFileRef->Void) :Void;
	function get (id :ObjectID, cb :MongoErr->GridStore->Void) :Void;
	function delete (id :ObjectID, cb :MongoErr->Bool->Void) :Void;
}

/** Static methods from GridStore */
typedef GridFS = {
	function readlines(db :Database, fileName :String, seperator :String, options :MongoQuery, cb :MongoErr->Array<String>->Void) :Void;	
}

/** Static methods from GridStore */
typedef ObjectIdStatic = {
	function generate() :ObjectID;	
}

class Mongo
{
	public static var mongo :Dynamic;
	public static var grid :GridFS;
	public static var objectID :ObjectIdStatic;
	
	public static function createObjectIDFromHexString (s :String) :ObjectID
	{
		var BSON = mongo.BSONPure;
		return untyped __js__('new BSON.ObjectID(s)');
	}
	
	public static function gridFs (db :Database, fsName :String) :Grid
	{
		var grid = Node.require('mongodb/gridfs/grid');
		return untyped __js__('new grid.Grid(db, fsName)');
	}
	
	public static function newGridStore (db :Database, filename :String, mode :String, ?options :MongoOptions) :GridStore
	{
		var gs = Node.require('mongodb/gridfs/gridstore');
		return untyped __js__('new gs.GridStore(db, filename, mode, options)');
	}
	
	static function __init__ () :Void
	{
		mongo = Node.require('mongodb');
		grid = mongo.GridStore;
		objectID = mongo.ObjectID;
	} 
}
