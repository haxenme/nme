package nme;

#if flash
typedef Vector<T> = flash.Vector<T>;
#else 
typedef Vector<T> = Array<T>;
#end
