package nme.display;


#if neko

typedef BitmapInt32 = { rgb:Int, a:Int };

#else

typedef BitmapInt32 = Int;

#end