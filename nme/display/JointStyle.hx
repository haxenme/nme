package nme.display;

#if (cpp || neko)

typedef JointStyle = neash.display.JointStyle;

#elseif js

typedef JointStyle = jeash.display.JointStyle;

#else

typedef JointStyle = flash.display.JointStyle;

#end