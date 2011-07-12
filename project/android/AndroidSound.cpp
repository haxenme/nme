#include <Sound.h>
#include <Display.h>
#include <jni.h>

#include <android/log.h>

#undef LOGV
#undef LOGE

//#define LOGV(msg,args...)
#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

extern JNIEnv *gEnv;

namespace nme
{

class AndroidSoundChannel : public SoundChannel
{
public:
   AndroidSoundChannel(Object *inSound, int inHandle,
							  double startTime, int loops, const SoundTransform &inTransform)
	{
		mStreamID = -1;
		mSound = inSound;
		inSound->IncRef();
		if (inHandle>=0)
		{
		   jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
         jmethodID mid = gEnv->GetStaticMethodID(cls, "playSound", "(IDDI)I");
         if (mid > 0)
		   {
			      mStreamID = gEnv->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops );
		   }
		}
    }

   ~AndroidSoundChannel()
   {
      mSound->DecRef();
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

	Object *mSound;
	int mStreamID;
};



class AndroidMusicChannel : public SoundChannel
{
public:
   AndroidMusicChannel(Object *inSound, int inHandle,
							  double startTime, int loops, const SoundTransform &inTransform)
	{
		mState = 0;
		mSound = inSound;
		inSound->IncRef();

		if (inHandle>=0)
		{
		   jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
         jmethodID mid = gEnv->GetStaticMethodID(cls, "playMusic", "(IDDI)I");
         if (mid > 0)
		   {
			   mState = gEnv->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops );
		   }
		}
    }

   ~AndroidMusicChannel()
   {
      mSound->DecRef();
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

	Object *mSound;
   int mState;
};







class AndroidSound : public Sound
{
   enum SoundMode
   {
      MODE_UNKNOWN,
      MODE_SOUND_ID,
      MODE_MUSIC_RES_ID,
      MODE_MUSIC_NAME,
   };

public:
	AndroidSound(const std::string &inSound, bool inForceMusic)
	{
		IncRef();

      mMode = MODE_UNKNOWN;
		mID = -1;
		jclass cls = gEnv->FindClass("org/haxe/nme/GameActivity");
		jstring str = gEnv->NewStringUTF( inSound.c_str() );

      if (!inForceMusic)
      {
         jmethodID mid = gEnv->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
         if (mid > 0)
		   {
			   mID = gEnv->CallStaticIntMethod(cls, mid, str);
            if (mID>=0)
               mMode = MODE_SOUND_ID;
		   }
      }

      if (mID<0)
      {
         jmethodID gmh = gEnv->GetStaticMethodID(cls, "getMusicHandle", "(Ljava/lang/String;)I");
         if (gmh>0)
         {
			   mID = gEnv->CallStaticIntMethod(cls, gmh, str);
            if (mID>0)
               mMode = MODE_MUSIC_RES_ID;
         }
      }

      if (mID<0)
      {
         mMusicName = inSound;
         mMode = MODE_MUSIC_NAME;
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
      if (mMode==MODE_MUSIC_RES_ID)
		   return new AndroidMusicChannel(this,mID,startTime,loops,inTransform);


		return new AndroidSoundChannel(this,mID,startTime,loops,inTransform);
	}

	int mID;
   std::string mMusicName;
   SoundMode mMode;
};


Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
	return new AndroidSound(inFilename,inForceMusic);
}



}
