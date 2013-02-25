package nme;


#if flash
private typedef VectorData<T> = flash.Vector<T>;
#else
private typedef VectorData<T> = Array<T>;
#end


@:arrayAccess abstract Vector<T>(VectorData<T>) {
	
	@:from static public inline function fromArray(a:Array<T>) {
		
        #if flash
		return new flash.Vector<T> (a);
		#else
		return cast a;
		#end
		
    }
	
}