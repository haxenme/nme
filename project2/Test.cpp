#include <Graphics.h>

Graphics gGraphics;
RenderState gState;

void Handler(Event &ioEvent,void *inStage)
{
	Stage *stage = (Stage *)inStage;

	static int tx = 0;
	static float rot = 0;
	tx = (tx+1) % 100;
	rot += 1;
	if (rot>360) rot-=360;

	if (ioEvent.mType==etNextFrame)
	{
		Surface *surface = stage->GetPrimarySurface();
		AutoSurfaceRender render(surface,0,stage);
		surface->Clear(0);
		gState.mTransform.mMatrix = Matrix().Rotate(rot).Translate(tx+100,80);
		gState.mClipRect = Rect( surface->Width(), surface->Height() );
		gState.mTransform.mAAFactor = 1;
		gState.mAAClipRect = gState.mClipRect * gState.mTransform.mAAFactor;

		gGraphics.Render(render.Target(),gState);
	}
}


int main(int inargc,char **arvg)
{
   Frame *frame = CreateMainFrame(640,400,wfResizable,"Hello");

	frame->GetStage()->SetEventHandler(Handler,frame->GetStage());

	gGraphics.lineStyle(5,0xff0000,0.5);
	gGraphics.beginFill(0xffffff);
	gGraphics.moveTo(-100,-100);
	gGraphics.lineTo(-100,100);
	gGraphics.lineTo(100,100);
	gGraphics.lineTo(100,-100);
	gGraphics.lineTo(-100,-100);

	Extent2DF ext = gGraphics.GetExtent(gState.mTransform);
	printf("Extent %f,%f ... %f,%f\n", ext.mMinX, ext.mMinY, ext.mMaxX, ext.mMaxY);

   MainLoop();
   delete frame;
   return 0;
}
