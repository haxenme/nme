#include <Sound.h>
#include <Display.h>
#include <jni.h>

#include <android/log.h>

#undef LOGV
#undef LOGE

#define LOGV(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)
#define LOGE(msg,args...) __android_log_print(ANDROID_LOG_ERROR, "NME::AndroidSound", msg, ## args)

extern JNIEnv *GetEnv();

namespace nme
{
	class AndroidSoundChannel : public SoundChannel
	{
	public:
	   	AndroidSoundChannel(Object *inSound, int inHandle, double startTime, int loops, const SoundTransform &inTransform)
		{
			//LOGV("Android Sound Channel create, in handle, %d",inHandle);
	      	JNIEnv *env = GetEnv();
			mStreamID = -1;
			mSound = inSound;
			inSound->IncRef();
			if (inHandle>=0)
			{
			   	jclass cls = env->FindClass("org/haxe/nme/Sound");
	         	jmethodID mid = env->GetStaticMethodID(cls, "playSound", "(IDDI)I");
	         	if (mid > 0)
			   	{
					// LOGV("Android Sound Channel found play method");
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
			if (mStreamID > -1) {	
				JNIEnv *env = GetEnv();

				jclass cls = env->FindClass("org/haxe/nme/Sound");
			    jmethodID mid = env->GetStaticMethodID(cls, "stopSound", "(I)V");
			    if (mid > 0){
					env->CallStaticVoidMethod(cls, mid, mStreamID);
				}
			}
		}

		void setTransform(const SoundTransform &inTransform)
		{
		}

		Object *mSound;
		int mStreamID;
	};

	SoundChannel *SoundChannel::Create(const ByteArray &inBytes,const SoundTransform &inTransform)
	{
		return 0;
	}


	class AndroidMusicChannel : public SoundChannel
	{
	public:
		AndroidMusicChannel(Object *inSound, int inHandle, double startTime, int loops, const SoundTransform &inTransform)
		{
			JNIEnv *env = GetEnv();
			mState = 0;
			mSound = inSound;
			inSound->IncRef();

			if (inHandle >= 0)
			{
				jclass cls = env->FindClass("org/haxe/nme/Sound");
				jmethodID mid = env->GetStaticMethodID(cls, "playMusic", "(IDDID)I");
				if (mid > 0) {
					mState = env->CallStaticIntMethod(cls, mid, inHandle, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops, startTime);
				}
			}
	    }

		AndroidMusicChannel(Object *inSound, const std::string &inPath, double startTime, int loops, const SoundTransform &inTransform)
		{
			JNIEnv *env = GetEnv();
			mState = 0;
			mSound = inSound;
			inSound->IncRef();

			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jstring path = env->NewStringUTF(inPath.c_str());
			jmethodID mid = env->GetStaticMethodID(cls, "playMusic", "(Ljava/lang/String;DDID)I");
			if (mid > 0) {
				mState = env->CallStaticIntMethod(cls, mid, path, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2), loops, startTime);
			}
	    }

		~AndroidMusicChannel()
		{
			mSound->DecRef();
		}

		bool isComplete()
		{
			JNIEnv *env = GetEnv();
			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "getMusicComplete", "()Z");
			if (mid > 0) {
				return env->CallStaticBooleanMethod(cls, mid);
			}
			return false;
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
			JNIEnv *env = GetEnv();

			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "stopMusic", "()V");
			if (mid > 0) {
				env->CallStaticVoidMethod(cls, mid);
			}
		}

		void setTransform(const SoundTransform &inTransform)
		{
			JNIEnv *env = GetEnv();

			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "setMusicTransform", "(DD)V");
			if (mid > 0 ) {
				env->CallStaticVoidMethod(cls, mid, inTransform.volume*((1-inTransform.pan)/2), inTransform.volume*((inTransform.pan+1)/2));
			}
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
			MODE_MUSIC_PATH,
		};

	public:
		AndroidSound(const std::string &inPath, bool inForceMusic)
		{
			JNIEnv *env = GetEnv();
			IncRef();

			mMode = MODE_UNKNOWN;
			handleID = -1;
			mLength = 0;
			mManagerID = getSoundPoolID();
			mSoundPath = inPath;

			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jstring path = env->NewStringUTF(mSoundPath.c_str());

			if (!inForceMusic) {
				jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
				if (mid > 0) {
					handleID = env->CallStaticIntMethod(cls, mid, path);
					if (handleID >= 0)
						mMode = MODE_SOUND_ID;
				}
			}

			if (handleID < 0) {
				jmethodID gmh = env->GetStaticMethodID(cls, "getMusicHandle", "(Ljava/lang/String;)I");
				if (gmh > 0) {
					handleID = env->CallStaticIntMethod(cls, gmh, path);
					if (handleID > 0)
						mMode = MODE_MUSIC_RES_ID;
				}
			}
			//env->ReleaseStringUTFChars(str, inSound.c_str() );

			if (handleID < 0)
				mMode = MODE_MUSIC_PATH;
		}

		void reloadSound()
		{
			JNIEnv *env = GetEnv();
			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "getSoundHandle", "(Ljava/lang/String;)I");
			if (mid > 0) {
				jstring path = env->NewStringUTF(mSoundPath.c_str());
				handleID = env->CallStaticIntMethod(cls, mid, path);
				//env->ReleaseStringUTFChars(path, mSoundName.c_str() );
			}
		}

		int getBytesLoaded() { return 0; }
		int getBytesTotal() { return 0; }
		bool ok() { return handleID >= 0; }
		std::string getError() { return ok() ? "" : "Error"; }

		double getLength()
		{
			if (mLength == 0 && handleID > 0) {
				JNIEnv *env = GetEnv();
				jclass cls = env->FindClass("org/haxe/nme/Sound");
				jstring path = env->NewStringUTF(mSoundPath.c_str());
				jmethodID mid = env->GetStaticMethodID(cls, "getSoundLength", "(Ljava/lang/String;)I");
				if (mid > 0) {
					mLength = env->CallStaticIntMethod(cls, mid, path);
				}
			}
		    return mLength;
		}
	   
	    void close()  { }

		int getSoundPoolID()
		{
			JNIEnv *env = GetEnv();
			jclass cls = env->FindClass("org/haxe/nme/Sound");
			jmethodID mid = env->GetStaticMethodID(cls, "getSoundPoolID", "()I");
			if (mid > 0) {
				return env->CallStaticIntMethod(cls, mid);
			}
			return 0;
		}

		SoundChannel *openChannel(double startTime, int loops, const SoundTransform &inTransform)
		{
			switch (mMode) {
				case MODE_MUSIC_RES_ID:
					return new AndroidMusicChannel(this, handleID, startTime, loops, inTransform);
					break;
				case MODE_SOUND_ID:
					{
						int mid = getSoundPoolID();
						if (mid != mManagerID) {
							mManagerID = mid;
							reloadSound();
						}
						return new AndroidSoundChannel(this, handleID, startTime, loops, inTransform);
					}
					break;
				case MODE_MUSIC_PATH:
				default:
					return new AndroidMusicChannel(this, mSoundPath, startTime, loops, inTransform);
					break;
			}
		}

		int handleID;
		int mLength;
		int mManagerID;
		std::string mSoundPath;
		SoundMode mMode;
	};

	Sound *Sound::Create(const std::string &inFilename,bool inForceMusic)
	{
		return new AndroidSound(inFilename,inForceMusic);
	}

	Sound *Sound::Create(unsigned char *inData, int len, bool inForceMusic)
	{
	}
}
