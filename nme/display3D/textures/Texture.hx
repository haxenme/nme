package nme.display3D.textures;

#if flash
typedef Texture = flash.display3D.textures.Texture;
#elseif cpp
typedef Texture = native.display3D.textures.Texture;
#end