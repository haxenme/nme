package nme.ui;

#if (cpp || neko)

typedef MultitouchInputMode = neash.ui.MultitouchInputMode;

#elseif js

typedef MultitouchInputMode = jeash.ui.MultitouchInputMode;

#else

typedef MultitouchInputMode = flash.ui.MultitouchInputMode;

#end