package js.node.mongo;

import js.node.mongo.Mongo;
import org.transition9.async.AsyncLambda;

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
					done();
				});
			}, 
			//Called on complete
			function (err) :Void {
				if (err != null) trace(Std.string(err));
				if (self.ready != null) {
					self.ready();
				} else {
					//trace("ready, but there's no ready callback, FYI");
				}
			});
	}
	
	public function close (cb :Void->Void) :Void
	{
		for (conn in connections) {
			conn.close(function(?_) {});
		}
		cb();
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
