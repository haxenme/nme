package nme.ui;

#if (cpp || neko)

typedef Keyboard = neash.ui.Keyboard;

#elseif js

typedef Keyboard = jeash.ui.Keyboard;

#else

typedef Keyboard = flash.ui.Keyboard;

#end