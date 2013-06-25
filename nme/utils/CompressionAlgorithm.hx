package nme.utils;
#if (cpp || neko)

enum CompressionAlgorithm 
{
   DEFLATE;
   ZLIB;
   LZMA;
   GZIP;
}

#else
typedef CompressionAlgorithm = flash.utils.CompressionAlgorithm;
#end