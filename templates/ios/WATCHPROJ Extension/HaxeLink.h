#ifndef HAXE_LINK_H
#define HAXE_LINK_H

enum HaxeFunctionId
{
   HxOnAwake = 0,
   HxWillActivate = 1,
   HxDidActivate = 2,
   HxApplicationDidFinishLaunching = 3,
   HxApplicationDidBecomeActive = 4,
   HxApplicationWillResignActive = 5,
   HxOnButton = 6,
};

typedef int (*HxHaxeCall)(int inFunction, int inParam);

void HxSetHaxeCallback( HxHaxeCall inCall );

int HxCall(int inFunction, int inParam=0);

void HxBoot();

#endif

