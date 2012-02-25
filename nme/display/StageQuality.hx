package nme.display;
#if (cpp || neko || js)


enum StageQuality
{
   LOW;
   MEDIUM;
   HIGH;
   BEST;
}


#else
typedef StageQuality = flash.display.StageQuality;
#end