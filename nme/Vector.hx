package nme;


#if flash
typedef Vector<T> = flash.Vector<T>;
#else 
typedef Vector<T> = Array<T>;

class VectorHelper
{
	
	public static inline function ofArray<T>(v:Class<Vector<Dynamic>>, array:Array<T>):Vector<T>
	{
		return array;
	}
	
}

#end
