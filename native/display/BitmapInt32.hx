package native.display;


#if (neko && !neko_v2)
typedef BitmapInt32 = { rgb:Int, a:Int };
#else
typedef BitmapInt32 = Int;
#end
