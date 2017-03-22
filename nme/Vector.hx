package nme;

#if flash
typedef VectorData<T> = flash.Vector<T>;

private class VectorIterator<T> {
	private var index:Int;
	private var data:VectorData<T>;

	public inline function new(data:VectorData<T>) {
		index = 0;
		this.data = data;
	}

	public function hasNext():Bool {
		return index < data.length;
	}

	public function next():T {
		return data[index++];
	}
}

#else
private typedef VectorData<T> = Array<T>;
#end

@:nativeProperty
@:arrayAccess abstract Vector<T>(VectorData<T>) {
	
	
	public var length(get, set):Int;
	public var fixed(get, set):Bool;
	
	
	public inline function new(?length:Int, ?fixed:Bool):Void {
		
		#if flash
		this = new flash.Vector<T>(length, fixed);
		#else
		this = new Array<T>();
		#end
		
	}
	
	
	public inline function concat(?a:VectorData<T>):Vector<T> {
		
		return cast this.concat(a);
		
	}
	
	
	public inline function copy():Vector<T> {
		
		#if flash
		return cast this.concat();
		#else
		return this.copy();
		#end
		
	}
	
	
	public inline function iterator<T>():Iterator<T> {
		
		#if flash
		return new VectorIterator(this);
		#else
		return this.iterator();
		#end
		
	}
	
	
	public inline function join(sep:String):String {
		
		return this.join(sep);
		
	}
	
	
	public inline function pop():Null<T> {
		
		return this.pop();
		
	}
	
	
	public inline function push(x:T):Int {
		
		return this.push(x);
		
	}
	
	
	public inline function reverse():Void {
		
		this.reverse();
		
	}
	
	
	public inline function shift():Null<T> {
		
		return this.shift();
		
	}
	
	
	public inline function unshift(x:T):Void {
		
		this.unshift(x);
		
	}
	
	
	public inline function slice(?pos:Int, ?end:Int):Vector<T> {
		
		return cast this.slice(pos, end);
		
	}
	
	
	public inline function sort(f:T -> T -> Int):Void {
		
		this.sort(f);
		
	}
	
	
	public inline function splice(pos:Int, len:Int):Vector<T> {
		
		return cast this.splice(pos, len);
		
	}
	
	
	public inline function toString():String {
		if(this == null)
            		return "null";
		
		return this.toString();
		
	}
	
	
	public inline function indexOf(x:T, ?from:Int = 0):Int {
		
		#if flash
		return this.indexOf(x, from);
		#else
		var value = -1;
		for (i in from...this.length) {
			if (this[i] == x) {
                value = i;
                break;
            }
		}
		return value;
		#end
		
	}
	
	
	public inline function lastIndexOf(x:T, ?from:Int = 0):Int {
		
		#if flash
		return this.lastIndexOf(x, from);
		#else
		var i = this.length - 1;
        var value = -1;
		while (i >= from) {
			if (this[i] == x) {
                value = i;
                break;
            }
			i--;
		}
		return value;
		#end
		
	}
	
	
	public inline static function ofArray<T>(a:Array<Dynamic>):Vector<T> {
		
		#if flash
		return cast flash.Vector.ofArray (a);
		#else
		return new Vector<T>().concat (cast a);
		#end
		
	}
	
	
	public inline static function convert<T,U>(v:VectorData<T>):Vector<U> {
		
		#if flash
		return cast flash.Vector.convert (v);
		#else
		return cast v;
		#end
		
	}
	
	
	@:from static public inline function fromArray<T, U>(a:Array<U>):Vector<T> {
		
        #if flash
		return cast flash.Vector.ofArray (a);
		#else
		return cast a;
		#end
		
    }
	
	
	#if flash
	@:to public inline function toVector<T>():flash.Vector<T> {
		return this;
	}
	#else
	@:to public inline function toArray<T>():Array<T> {
		
		return this;
		
    }
	#end
	
	
	
	
	// Getters & Setters
	
	
	
	
	private inline function get_length():Int {
		
		return this.length;
		
	}
	
	
	private inline function set_length(value:Int):Int {
		
		#if flash
		return this.length = value;
		#else
		return value;
		#end
		
	}
	
	
	private inline function get_fixed():Bool {
		
		#if flash
		return this.fixed;
		#else
		return false;
		#end
		
	}
	
	
	private inline function set_fixed(value:Bool):Bool {
		
		#if flash
		return this.fixed = value;
		#else
		return value;
		#end
		
	}
	
	
}


