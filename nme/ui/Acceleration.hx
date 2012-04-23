package nme.ui;
#if code_completion


typedef Acceleration = 
{
	x:Float,
	y:Float,
	z:Float 
}


#elseif (cpp || neko)
typedef Acceleration = neash.ui.Acceleration;
#end