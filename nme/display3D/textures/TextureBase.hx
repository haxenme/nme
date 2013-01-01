package nme.display3D.textures;
#if display


extern class TextureBase extends nme.events.EventDispatcher {
	function dispose() : Void;
}}


#elseif (cpp || neko)
typedef TextureBase = native.display3D.textures.TextureBase;
#elseif !js
typedef TextureBase = flash.display3D.textures.TextureBase;
#end