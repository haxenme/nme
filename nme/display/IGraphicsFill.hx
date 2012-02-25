package nme.display;
#if js

interface IGraphicsFill 
{
	var jeashGraphicsFillType(default,null):GraphicsFillType;
}

@:fakeEnum(Int) enum GraphicsFillType 
{
	SOLID_FILL;
	GRADIENT_FILL;
}

#end