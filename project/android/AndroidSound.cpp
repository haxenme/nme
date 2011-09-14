#include <Sound.h>
#include <Display.h>
#include <jni.h>

#include <android/log.h>

#undef LOGV
#undef LOGE

//#define LOGV(msg,args...)
#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

extern JNIEnv *GetEnv();

namespace nme
{

class AndroidSoundChannel : public SoundChannel
{
public:
   AndroidSoundChannel(Object *inSound, int inHandle,
							  double startTime, int loops, const SoundTransform &inTransform)
	{
      JNIEnv *env = GetEnv();
		mStreamID = -1;
		mSound = inSound;
		inSound->IncRef();
		if (inHandle>=0)
		{
		   jclass cls = env->FindClass("org/haxe/nme/GameActivity");
         jmethodID mid = env->GetStaticMethodID(cls, "playSound", "(IDDI)I");
         if (mid > 0)
		   {
			      mStreamID = env->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops );
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
      JNIEnv *env = GetEnv();
		mState = 0;
		mSound = inSound;
		inSound->IncRef();

		if (inHandle>=0)
		{
		   jclass cls = env->FindClass("org/haxe/nme/GameActivity");
         jmethodID mid = env->GetStaticMethodID(cls, "playMusic", "(IDDI)I");
         if (mid > 0)
		   {
			   mState = env->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops );
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
      JNIEnv *env = GetEnv();
		IncRef();

      mMode = MODE_UNKNOWN;
		mID = -1;
      mManagerID = getSoundPoolID();
      mSoundName = inSound;

		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
		jstring str = env->NewStringUTF( inSound.c_str() );

      if (!inForceMusic)
      {
         jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
         if (mid > 0)
		   {
			   mID = env->CallStaticIntMethod(cls, mid, str);
            if (mID>=0)
               mMode = MODE_SOUND_ID;
		   }
      }

      if (mID<0)
      {
         jmethodID gmh = env->GetStaticMethodID(cls, "getMusicHandle", "(Ljava/lang/String;)I");
         if (gmh>0)
         {
			   mID = env->CallStaticIntMethod(cls, gmh, str);
            if (mID>0)
               mMode = MODE_MUSIC_RES_ID;
         }
      }
      //env->ReleaseStringUTFChars(str, inSound.c_str() );

      if (mID<0)
         mMode = MODE_MUSIC_NAME;
	}

   void reloadSound()
   {
      JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
      jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
      if (mid > 0)
		{
		    jstring str = env->NewStringUTF( mSoundName.c_str() );
			 mID = env->CallStaticIntMethod(cls, mid, str);
          //env->ReleaseStringUTFChars(str, mSoundName.c_str() );
		}
   }

   int getBytesLoaded() { return 0; }
   int getBytesTotal() { return 0; }
   bool ok() { return mID >= 0; }
   std::string getError() { return ok() ? "" : "Error"; }
   double getLength() { return 0; }
   void close()  { }

   int getSoundPoolID()
   {
      JNIEnv *env = GetEnv();
		jclass cls = env->FindClass("org/haxe/nme/GameActivity");
      jmethodID mid = env->GetStaticMethodID(cls, "getSoundPoolID", "()I");
      if (mid > 0)
		{
		   return env->CallStaticIntMethod(cls, mid );
		}
      return 0;
   }


   SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
	{
      if (mMode==MODE_MUSIC_RES_ID)
		   return new AndroidMusicChannel(this,mID,startTime,loops,inTransform);

      int mid = getSoundPoolID();
      if (mid!=mManagerID)
      {
          mManagerID = mid;
          reloadSound();
      }

		return new AndroidSoundChannel(this,mID,startTime,loops,inTransform);
	}

	int mID;
   int mManagerID;
   std::string mSoundName;
   SoundMode mMode;
};


Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
{
	return new AndroidSound(inFilename,inForceMusic);
}



}
