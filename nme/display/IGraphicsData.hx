package nme.display;
#if (cpp || neko)


class IGraphicsData
{	
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	
	public function new(inHandle:Dynamic)
	{
		nmeHandle = inHandle;	
	}
	
}


#elseif js

interface IGraphicsData 
{
	var jeashGraphicsDataType(default,null):GraphicsDataType;
}

@:fakeEnum(Int) enum GraphicsDataType 
{
	STROKE;
	SOLID;
	GRADIENT;
	PATH;
}

#else
typedef IGraphicsData = flash.display.IGraphicsData;
#end