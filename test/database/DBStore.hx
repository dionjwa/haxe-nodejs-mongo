package database;

class DBStore
	implements haxe.rtti.Infos
{
	#if nodejs
	static var _indexOn :Array<{name:String, filter:Dynamic->Dynamic}> = [
		{name :"a",filter :function(el :Dynamic) {
			return el.a; }
		}
	];
	#end
	
	public var _id :String;
	public var a :Int;
	public var b :String;
	
	public function new ()
	{
		a = 1;
		b = "crap";
	}
	
	public function toString () :String
	{
		return "[DBStore _id=" + _id + ", a=" + a + ", b=" + b + "]";
	}
}
