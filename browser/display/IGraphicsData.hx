package browser.display;
#if js


interface IGraphicsData {
	
	var nmeGraphicsDataType(default, null):GraphicsDataType;
	
}


@:fakeEnum(Int) enum GraphicsDataType {
	
	STROKE;
	SOLID;
	GRADIENT;
	PATH;
	
}


#end