package native.display;
#if (cpp || neko)

#if neko
typedef BitmapInt32 = { rgb:Int, a:Int };
#else
typedef BitmapInt32 = Int;
#end

#end