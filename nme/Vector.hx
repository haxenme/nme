package nme;
#if (cpp || neko)


typedef Vector<T> = Array<T>;


#else
typedef Vector<T> = flash.Vector<T>;
#end