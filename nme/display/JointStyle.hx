package nme.display;
#if (cpp || neko)


enum JointStyle {
	
	ROUND; // default
	MITER;
	BEVEL;
	
}


#else
typedef JointStyle = flash.display.JointStyle;
#end