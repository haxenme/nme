package nme.display;


#if (neko && (!haxe3 || neko_v1))
typedef BitmapInt32 = { rgb:Int, a:Int };
#else
typedef BitmapInt32 = Int;
#end
