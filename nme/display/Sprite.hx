package nme.display;

#if (cpp || neko)

typedef Sprite = neash.display.Sprite;

#elseif js

typedef Sprite = jeash.display.Sprite;

#else

typedef Sprite = flash.display.Sprite;

#end