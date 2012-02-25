package nme.display;
#if (cpp || neko || js)


enum JointStyle
{	
	ROUND; // default
	MITER;
	BEVEL;	
}


#else
typedef JointStyle = flash.display.JointStyle;
#end