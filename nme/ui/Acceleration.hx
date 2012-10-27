package nme.ui;
#if display


typedef Acceleration = 
{
	x:Float,
	y:Float,
	z:Float 
}

#elseif (cpp || neko)
typedef Acceleration = neash.ui.Acceleration;
#elseif js
typedef Acceleration = jeash.ui.Acceleration;
#end