package nme;
#if !haxe3


#if flash
typedef Vector<T> = flash.Vector<T>;
#else
typedef Vector<T> = Array<T>;
#end


#else


#if flash
private typedef VectorData<T> = flash.Vector<T>;
#else
private typedef VectorData<T> = Array<T>;
#end


@:arrayAccess abstract Vector<T>(VectorData<T>) {
	
	
	public var length(get, set):Int;
	public var fixed(get, set):Bool;
	
	
	public function new(?length:Int, ?fixed:Bool):Void {
		
		#if flash
		this = new flash.Vector<T>(length, fixed);
		#else
		this = new Array<T>();
		#end
		
	}
	
	
	public function concat(?a:VectorData<T>):Vector<T> {
		
		return cast this.concat(a);
		
	}
	
	
	public function copy():Vector<T> {
		
		#if flash
		return cast this.concat();
		#else
		return this.copy();
		#end
		
	}
	
	
	public function iterator<T>():Iterator<T> {
		
		#if flash
		return new VectorIter(this);
		#else
		return this.iterator();
		#end
		
	}
	
	
	public function join(sep:String):String {
		
		return this.join(sep);
		
	}
	
	
	public function pop():Null<T> {
		
		return this.pop();
		
	}
	
	
	public function push(x:T):Int {
		
		return this.push(x);
		
	}
	
	
	public function reverse():Void {
		
		this.reverse();
		
	}
	
	
	public function shift():Null<T> {
		
		return this.shift();
		
	}
	
	
	public function unshift(x:T):Void {
		
		this.unshift(x);
		
	}
	
	
	public function slice(?pos:Int, ?end:Int):Vector<T> {
		
		return cast this.slice(pos, end);
		
	}
	
	
	public function sort(f:T -> T -> Int):Void {
		
		this.sort(f);
		
	}
	
	
	public function splice(pos:Int, len:Int):Vector<T> {
		
		return cast this.splice(pos, len);
		
	}
	
	
	public function toString():String {
		
		return this.toString();
		
	}
	
	
	public function indexOf(x:T, ?from:Int = 0):Int {
		
		#if flash
		return this.indexOf(x, from);
		#else
		for (i in from...this.length) {
			if (this[i] == x) return i;
		}
		return -1;
		#end
		
	}
	
	
	public function lastIndexOf(x:T, ?from:Int = 0):Int {
		
		#if flash
		return this.lastIndexOf(x, from);
		#else
		var i = this.length - 1;
		while (i >= from) {
			if (this[i] == x) return i;
			i--;
		}
		return -1;
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
	
	
	#if !flash
	@:to public inline function toArray<T>():Array<T> {
		
		return this;
		
    }
	#end
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_length():Int {
		
		return this.length;
		
	}
	
	
	private function set_length(value:Int):Int {
		
		#if flash
		return this.length = value;
		#else
		return value;
		#end
		
	}
	
	
	private function get_fixed():Bool {
		
		#if flash
		return this.fixed;
		#else
		return false;
		#end
		
	}
	
	
	private function set_fixed(value:Bool):Bool {
		
		#if flash
		return this.fixed = value;
		#else
		return value;
		#end
		
	}
	
	
}


#if flash
private class VectorIter<T> {
	
	
	private var index:Int;
    private var vector:flash.Vector<T>;
	
	
    public function new(vector:flash.Vector<T>) {
		
		index = 0;
        this.vector = vector;
		
    }
	
	
    public function hasNext() {
		
        return (index < vector.length - 1);
		
    }
	
	
    public function next() {
		
        return vector[index++];
		
    }
	
	
}
#end


#end