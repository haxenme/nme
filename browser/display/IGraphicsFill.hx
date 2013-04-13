package browser.display;
#if js


interface IGraphicsFill {
	
	var nmeGraphicsFillType(default, null):GraphicsFillType;
	
}


@:fakeEnum(Int) enum GraphicsFillType {
	
	SOLID_FILL;
	GRADIENT_FILL;
	
}


#end