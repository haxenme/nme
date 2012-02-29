package nme.ui;

#if (cpp || neko)

typedef Mouse = neash.ui.Mouse;

#elseif js

typedef Mouse = jeash.ui.Mouse;

#else

typedef Mouse = flash.ui.Mouse;

#end