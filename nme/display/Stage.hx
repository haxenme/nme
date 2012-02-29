package nme.display;

#if (cpp || neko)

typedef Stage = neash.display.Stage;

#elseif js

typedef Stage = jeash.display.Stage;

#else

typedef Stage = flash.display.Stage;

#end