#include <Sound.h>
#include <Display.h>
#include <jni.h>

extern JNIEnv *gEnv;

namespace nme
{

class AndroidSoundChannel : public SoundChannel
{
public:
   AndroidSoundChannel(int inHandle,double startTime, int loops, const SoundTransform &inTransform)
	{
		mStreamID = -1;
		if (inHandle>=0)
		{
		   if (loops==0) loops = 1;

		   jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
         jmethodID mid = gEnv->GetStaticMethodID(cls, "playSound", "(IDDI)I");
         if (mid > 0)
		   {
			      mStreamID = gEnv->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume, inTransform.volume, loops );
		   }
		}
	}

   bool isComplete()
	{
		return true;
	}
   double getLeft()
	{
		return 0.5;
	}
   double getRight()
	{
		return 0.5;
	}
   double getPosition()
	{
	}
   void stop()
	{
	}
   void setTransform(const SoundTransform &inTransform)
	{
	}

	int mStreamID;
};


class AndroidSound : public Sound
{
public:
	AndroidSound(const std::string &inSound, bool inForceMusic)
	{
		mID = -1;
		jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
      jmethodID mid = gEnv->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
      if (mid > 0)
		{
			jstring str = gEnv->NewStringUTF( inSound.c_str() );
			mID = gEnv->CallStaticIntMethod(cls, mid, str);
		}
	}

   int getBytesLoaded() { return 0; }
   int getBytesTotal() { return 0; }
   bool ok() { return mID >= 0; }
   std::string getError() { return ok() ? "" : "Error"; }
   double getLength() { return 0; }
   void close()  { }
   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
	{
		return new AndroidSoundChannel(mID,startTime,loops,inTransform);
	}

	int mID;
};


Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
	return new AndroidSound(inFilename,inForceMusic);
}



}
