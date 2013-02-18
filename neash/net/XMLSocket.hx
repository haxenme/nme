
package neash.net;

import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.Input;
import neash.events.DataEvent;
import neash.events.Event;
import neash.events.EventDispatcher;
import neash.events.IOErrorEvent;
import neash.utils.ByteArray;
import nme.ObjectHash;

class XMLSocket extends EventDispatcher
{
	public var connected(default, null): Bool;

    // Ignored by this implementation; you always get the default timeout
    public var timeout : Int;

    private var sock : sys.net.Socket;
    private var bytes : Bytes;
    private var partial : Bytes;

    private static var allXMLSockets = 
        new ObjectHash<sys.net.Socket, XMLSocket>();
    private static var readSockets = new Array<sys.net.Socket>();
    private static var writeSockets = new Array<sys.net.Socket>();

    public static function nmePollData()
    {
        if ((readSockets.length == 0) && (writeSockets.length == 0)) {
            return;
        }

        // Use select to poll the current read state of all sockets
        var result = sys.net.Socket.select(readSockets, writeSockets, null, 0);

        // Check for write-able sockets, which indicates that the connection
        // has completed
        for (sock in result.write) {
            allXMLSockets.get(sock).writeReady();
        }

        for (sock in result.read) {
            // For each socket that is readable, tell it to read more data
            allXMLSockets.get(sock).readReady();
        }
    }

    public function new(?host : String, port : Int = 80) : Void
    {
        super();

        bytes = Bytes.alloc(16384);

        if (host != null) {
            connect(host, port);
        }
    }

    public function close() : Void
    {
        sock.close();
        allXMLSockets.remove(sock);
        readSockets.remove(sock);
        writeSockets.remove(sock);
        partial = null;
    }

    public function connect(host : String, port : Int) : Void
    {
        sock = new sys.net.Socket();
        sock.setBlocking(false);

        allXMLSockets.set(sock, this);
        readSockets.push(sock);
        writeSockets.push(sock);

        connected = false;
        sock.connect(new sys.net.Host(host), port);
    }

    public function send(object : Dynamic) : Void
    {
        sock.output.writeString(object.toString());
        sock.output.writeByte(0);
    }

    private function readReady() : Void
    {
        // Read all data available from the socket
        var read_something = false;
        while (true) {
            var len = readAvailable(sock.input, bytes);

            if (len == 0) {
                break;
            }

            read_something = true;
        
            // For each string in the output bytes, send a whole data event
            var first_unused : Int = 0;
            for (i in 0...len) {
                if (bytes.get(i) == 0) {
                    if (i > first_unused) {
                        dispatchDataEvent
                            (bytes, first_unused, i - first_unused);
                    }
                    first_unused = i + 1;
                }
            }

            // Save away the remaining partial string
            if (first_unused < len) {
                if (partial == null) {
                    partial = bytes.sub(first_unused, len - first_unused);
                }
                else {
                    var new_partial = Bytes.alloc
                        (partial.length + (len - first_unused));
                    new_partial.blit(0, partial, 0, partial.length);
                    new_partial.blit(partial.length, bytes, first_unused,
                                     len - first_unused);
                    partial = new_partial;
                }
            }
        }

        // If nothing was read, the socket has closed
        if (!read_something) {
            close();
            dispatchEvent(new Event(Event.CLOSE));
        }
    }

    private function writeReady() : Void
    {
        // No longer care about write-ability
        writeSockets.remove(sock);
        // Check to see if the socket has a peer; if it does, the connection
        // succeeded, if not, it failed
        var peer = sock.peer();
        if (peer.host == null) {
            dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
        }
        else {
            connected = true;
            dispatchEvent(new Event(Event.CONNECT));
        }
    }

    private function dispatchDataEvent(bytes : Bytes,
                                       pos : Int, len : Int) : Void
    {
        var data : String;
        // Special case the whole bytes
        if ((pos == 0) && (len == bytes.length)) {
            data = bytes.toString();
        }
        // Else use a substring
        else {
            data = bytes.readString(pos, len);
        }
        // If there was a saved partial from the last read, must compose a
        // full string from partial and the relevant part of bytes
        if (partial != null) {
            data = partial + data;
            partial = null;
        }

        dispatchEvent(new DataEvent(DataEvent.DATA, false, false, data));
    }

    // Returns the number of bytes read into Bytes
    private static function readAvailable(input : Input, bytes : Bytes) : Int
    {
        var total_read = 0;
        var pos = 0;

        while (pos < bytes.length) {
            var len;
            try {
                len = input.readBytes(bytes, pos, bytes.length - pos);
            }
            catch (e : Dynamic) {
                len = 0;
            }
            if (len == 0) {
                break;
            }
            total_read += len;
            pos += len;
        }
        return total_read;
    }
}
