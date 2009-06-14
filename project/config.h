#ifndef CONFIG_H
#define CONFIG_H

#ifdef IPHONE

#define NME_OPENGLES
#define NME_TTF

#else

#ifdef __APPLE__
  #define NME_MACBOOT
#endif



#define NME_OPENGL
#define NME_MIXER
#define NME_CLIPBOARD
#define NME_TTF
#define NME_IMAGE_IO

#endif

#if defined(NME_OPENGLES) || defined(NME_OPENGL)
#define NME_ANY_GL
#endif

#endif
