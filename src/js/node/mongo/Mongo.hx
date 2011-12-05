package js.node.mongo;

/**
  * Externs for using Mongodb directly in Node.js
  */
import AsyncLambda;
import haxe.serialization.Serialization;

import js.Node;

using Lambda;

typedef MongoErr = Dynamic;
typedef MongoObj = Dynamic;
typedef MongoQuery=Dynamic;
typedef MongoUpdate=Dynamic;

typedef Server = {
	var host :String;
	var port :Int;
	var options :Dynamic;
	var internalMaster :Bool;
	var autoReconnect :Bool;
}

typedef Database = {
	function open (cb :MongoErr->Database->Void) :Void;
	function close (cb :Dynamic->Void) :Void;
	function dropDatabase (cb :MongoErr->Dynamic->Void) :Void;
	function collection (name :String, cb :MongoErr->Collection->Void) :Void;
	function createCollection (name :String, cb :MongoErr->Collection->Void) :Void;
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
  var sort :String;
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
  function update(q :MongoQuery, d :Dynamic, options :Dynamic, cb :MongoErr->MongoObj->Void) :Void;
  function ensureIndex(q :MongoQuery) :Void;
}

class Mongo
{
	public static var mongo :Dynamic;
	
	public static function ObjectID (s :String) :Dynamic
	{
		var BSON = mongo.BSONPure;
		return untyped __js__('new BSON.ObjectID(s)');
	}
	
	static function __init__ () :Void
	{
		mongo = Node.require('mongodb');
	} 
}

class MongoPool 
{
	var host :String;
	var port :Int;
	var name :String;
	var size :Int;
	
	var connections :Array<Database>;
	public var ready :Void->Void;
	
	public function new(host :String,port :Int,name :String,size :Int) 
	{
		this.host = host;
		this.port = port;
		this.name = name;
		var me = this;
		connections = new Array();
		
		var arr = [];
		for (i in 0...size) {
			arr[i] = i;
		}
		
		var self = this;
		AsyncLambda.iter(arr, 
			//Called on each element
			function (i :Int, done :Void->Void) :Void {
				self.addConnection(function() {
					// trace("added connection");
					done();
				});
			}, 
			//Called on complete
			function (err) :Void {
				if (err != null) trace(Std.string(err));
				if (self.ready != null) {
					self.ready();
				} else {
					trace("ready, but there's no ready callback, FYI");
				}
			});
	}

	function addConnection(onAddition :Void->Void) 
	{
		var mongo = Mongo.mongo;
		var server :Server = untyped __js__("new mongo.Server(this.host, this.port, {})");
		var db :Database = untyped __js__("new mongo.Db(this.name, server)");
		var me = this;
		db.open(function(err, db) {
			if (err != null) trace("Error opening mongo database: " + err);
			me.connections.push(db);
			if (onAddition != null)
			  onAddition();
		});
	}

	public function connection(cb :Database->Void) :Void 
	{
		if (connections.length > 0) {
			cb(connections.pop());
		} else {
			var self = this;
			addConnection(function () :Void {
				cb(self.connections.pop());
			});
		}
	}

	public function returnConnection(c :Database) 
	{
		connections.push(c);
	}
}
