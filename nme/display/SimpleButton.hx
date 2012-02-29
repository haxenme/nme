package nme.display;

#if (cpp || neko)

typedef SimpleButton = neash.display.SimpleButton;

#elseif js

//typedef SimpleButton = jeash.display.SimpleButton;

#else

typedef SimpleButton = flash.display.SimpleButton;

#end