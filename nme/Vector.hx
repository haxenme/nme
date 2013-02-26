package nme;


#if flash
typedef Vector<T> = flash.Vector<T>;
#else
typedef Vector<T> = Array<T>;
#end

/*#if flash
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
	
	
	public function concat(?a:VectorData<T>):VectorData<T> {
		
		return this.concat(a);
		
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
	
	
	public function slice(pos:Int, ?end:Int):VectorData<T> {
		
		return this.slice(pos, end);
		
	}
	
	
	public function sort(f:T -> T -> Int):Void {
		
		this.sort(f);
		
	}
	
	
	public function splice(pos:Int, len:Int):VectorData<T> {
		
		return this.splice(pos, len);
		
	}
	
	
	public function toString():String {
		
		return this.toString();
		
	}
	
	
	public function indexOf(x:T, ?from:Int):Int {
		
		return this.indexOf(x, from);
		
	}
	
	
	public function lastIndexOf(x:T, ?from:Int):Int {
		
		return this.lastIndexOf(x, from);
		
	}
	
	
	public inline static function ofArray<T>(a:Array<T>):VectorData<T> {
		
		#if flash
		return flash.Vector.ofArray (a);
		#else
		return cast a;
		#end
		
	}
	
	
	public inline static function convert<T,U>(v:VectorData<T>):VectorData<U> {
		
		#if flash
		return flash.Vector.convert (v);
		#else
		return cast v;
		#end
		
	}
	
	
	@:from static public inline function fromArray<T>(a:Array<T>) {
		
        #if flash
		return cast flash.Vector.ofArray (a);
		#else
		return cast a;
		#end
		
    }
	
	
	
	
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
	
	
}*/