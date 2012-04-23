package nme.ui;
#if code_completion


@:fakeEnum(String) extern enum MultitouchInputMode {
	GESTURE;
	NONE;
	TOUCH_POINT;
}


#elseif (cpp || neko)
typedef MultitouchInputMode = neash.ui.MultitouchInputMode;
#elseif js
typedef MultitouchInputMode = jeash.ui.MultitouchInputMode;
#else
typedef MultitouchInputMode = flash.ui.MultitouchInputMode;
#end