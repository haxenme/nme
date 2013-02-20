package native.utils;
#if (cpp || neko)

enum CompressionAlgorithm 
{
   DEFLATE;
   ZLIB;
   LZMA;
   GZIP;
}

#end