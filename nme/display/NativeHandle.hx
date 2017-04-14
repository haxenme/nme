package nme.display;

#if cpp
typedef NativeHandle = Dynamic;
#elseif neko
typedef NativeHandle = Dynamic;
#elseif html5
typedef NativeHandle = nme.html5.DisplayObject;
#elseif jsprime
typedef NativeHandle = {
   var ptr:Int;
   var kind:Int;
}
#end
