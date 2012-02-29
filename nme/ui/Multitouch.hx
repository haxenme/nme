package nme.ui;

#if (cpp || neko)

typedef Multitouch = neash.ui.Multitouch;

#elseif js

typedef Multitouch = jeash.ui.Multitouch;

#else

typedef Multitouch = flash.ui.Multitouch;

#end