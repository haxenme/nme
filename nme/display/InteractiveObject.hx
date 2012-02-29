package nme.display;

#if (cpp || neko)

typedef InteractiveObject = neash.display.InteractiveObject;

#elseif js

typedef InteractiveObject = jeash.display.InteractiveObject;

#else

typedef InteractiveObject = flash.display.InteractiveObject;

#end