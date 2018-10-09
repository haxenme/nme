package nme;


#if jsprime
typedef NativeHandle = {
   var ptr:Int;
   var flags:Int;
}
#else
typedef NativeHandle = Dynamic;
#end

typedef NativeHandler = { var nmeHandle:NativeHandle; }
