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

   HxUpdateScene = 7,
   HxDidEvaluateActionsForScene = 8,
   HxDidSimulatePhysicsForScene = 9,
   HxDidApplyConstraintsForScene = 10,
   HxDidFinishUpdateForScene = 11,

};

typedef int (*HxHaxeCall)(int inFunction, int inIParam, double inDParam, void *inPtrParam);

void HxSetHaxeCallback( HxHaxeCall inCall );

int HxCall(int inFunction, int inIParam=0, double inDParam=0, void *inPtrParam=0);

void HxBoot();

#endif

