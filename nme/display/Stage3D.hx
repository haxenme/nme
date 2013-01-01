package nme.display;

#if flash
typedef Stage3D = flash.display.Stage3D;
#elseif cpp
typedef Stage3D = native.display.Stage3D;
#end
