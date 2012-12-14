package native.display;


#if neko
typedef BitmapInt32 = { rgb:Int, a:Int };
#else
typedef BitmapInt32 = Int;
#end