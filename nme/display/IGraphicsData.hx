package nme.display;
#if display


extern interface IGraphicsData {
}


#elseif (cpp || neko)
typedef IGraphicsData = native.display.IGraphicsData;
#elseif js
typedef IGraphicsData = browser.display.IGraphicsData;
#else
typedef IGraphicsData = flash.display.IGraphicsData;
#end
