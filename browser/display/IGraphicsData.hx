package browser.display;


interface IGraphicsData {
	
	var nmeGraphicsDataType (default, null):GraphicsDataType;
	
}


@:fakeEnum(Int) enum GraphicsDataType {
	
	STROKE;
	SOLID;
	GRADIENT;
	PATH;
	
}