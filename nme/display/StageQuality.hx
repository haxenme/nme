package nme.display;
#if (cpp || neko)


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