package nme.display;
#if (!flash)

enum SpreadMethod 
{
   PAD;
   REPEAT;
   REFLECT;
}

#else
typedef SpreadMethod = flash.display.SpreadMethod;
#end
