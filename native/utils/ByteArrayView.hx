package native.utils;

class ByteArrayView  extends ArrayBufferView {

    public function new(byteArray:ByteArray, inStart:Int = 0, ?inLen:Null<Int>) {
        super(byteArray, inStart, inLen);
    }


}
