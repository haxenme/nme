package nme.display;
#if (!flash)

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
