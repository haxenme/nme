package browser.display;


interface IGraphicsFill {
	
	var nmeGraphicsFillType (default, null):GraphicsFillType;
	
}


@:fakeEnum(Int) enum GraphicsFillType {
	
	SOLID_FILL;
	GRADIENT_FILL;
	
}