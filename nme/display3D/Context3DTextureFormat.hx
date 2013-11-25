package nme.display3D;
#if (cpp || neko)

enum Context3DTextureFormat 
{
    BGRA;
    COMPRESSED;
    COMPRESSED_ALPHA;
}

#else
typedef Context3DTextureFormat = flash.display3D.Context3DTextureFormat;
#end