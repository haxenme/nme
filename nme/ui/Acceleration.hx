package nme.ui;
#if display


typedef Acceleration = 
{
	x:Float,
	y:Float,
	z:Float 
}

#elseif (cpp || neko)
typedef Acceleration = native.ui.Acceleration;
#elseif js
typedef Acceleration = browser.ui.Acceleration;
#end