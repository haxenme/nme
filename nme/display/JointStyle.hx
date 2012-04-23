package nme.display;
#if code_completion


@:fakeEnum(String) extern enum JointStyle {
	BEVEL;
	MITER;
	ROUND;
}


#elseif (cpp || neko)
typedef JointStyle = neash.display.JointStyle;
#elseif js
typedef JointStyle = jeash.display.JointStyle;
#else
typedef JointStyle = flash.display.JointStyle;
#end