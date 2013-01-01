package native.display3D.textures;
import nme.display.BitmapData;
import nme.gl.GL;
import nme.utils.ArrayBuffer;
import nme.utils.ArrayBufferView;
class Texture {
    public var glTexture : nme.gl.Texture;
    public function new(glTexture : nme.gl.Texture) {
        this.glTexture = glTexture;
    }

    public function uploadFromBitmapData(bitmapData : BitmapData) : Void{
        GL.bindTexture(GL.TEXTURE_2D, glTexture);
        var p = bitmapData.getPixels(new nme.geom.Rectangle(0,0, bitmapData.width, bitmapData.height));
        var num =  bitmapData.width * bitmapData.height;
        for (i in 0...num){
            var alpha = p[i * 4];
            var red = p[i * 4 + 1];
            var green = p[i * 4 + 2];
            var blue = p[i * 4 + 3];
            p[i * 4] = red;
            p[i * 4 + 1] = green;
            p[i * 4 + 2] = blue;
            p[i * 4 + 3] = alpha;
        }
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, bitmapData.width, bitmapData.height, 0, GL.RGBA, GL.UNSIGNED_BYTE, new ArrayBufferView(p , 0));
    }
}
