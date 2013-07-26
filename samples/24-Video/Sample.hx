import nme.display.Sprite;
import nme.media.Video;

class Sample extends Sprite
{
   public function new()
   {
      super();
      var video = new Video(512, 288);
      video.load("Data/sample.ogv");
      video.smoothing = true;
      video.play();
      addChild(video);
   }
}