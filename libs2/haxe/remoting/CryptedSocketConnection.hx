package haxe.remoting;
import haxe.remoting.SocketProtocol.Socket;
import chx.crypt.IMode;

/**
 * Flash or JS to server using crypted sockets
 */
class CryptedSocketConnection extends SocketConnection, implements AsyncConnection, implements Dynamic<AsyncConnection> {

	function new(data,path) {
		super(data, path);
	}

	/**
	 * Convenience method to set the SocketProtocol cipher
	 **/
	public function setCipher(cipher:IMode):Void {
		var csp : CryptedSocketProtocol = cast getProtocol();
		csp.cipher = cipher;
	}

	/**
	 * Creates remoting communications over an remoting Socket. In neko,
	 * this can be used for real time communications with a Flash client which
	 * is using an XMLSocket to connect to the server.
	 * @param	s
	 * @param	ctx
	 * @param	cipher Set to null to disable encryption, or to a cipher to start secure communications.
	 */
	public static function create( s : Socket, ctx : Context=null, cipher:IMode=null ) {
		var data = {
			protocol : cast new CryptedSocketProtocol(s, ctx, cipher),
			results : new List(),
			error : function(e) throw e,
			log : null,
			#if !flash9
			#if (flash || js)
			queue : new haxe.TimerQueue(),
			#end
			#end
		};
		var sc : CryptedSocketConnection = new CryptedSocketConnection(data,[]);
		data.log = sc.defaultLog;
		#if flash9
		var buf : String = "";
		s.addEventListener(flash.events.DataEvent.DATA, function(e : flash.events.DataEvent) {
			var inData = buf + e.data;
			var o = sc.__data.protocol.decodeMessageLength(Bytes.ofStringData(inData), 0, inData.length);
			if ( o.length == null || inData.length - o.bytesUsed < o.length - 1 ) {
				var msg = o.length == null ? "Null length" : "len: " + inData.length + " used: " + o.bytesUsed + " o.len: " + o.length;
				sc.__data.error("Invalid message header: " + msg);
				return;
			}
			sc.processMessage(inData.substr(o.bytesUsed, o.length - 1));
			buf = inData.substr(o.bytesUsed + o.length - 1);
		});
		#elseif (flash || js)
		// we can't deliver directly the message
		// since it might trigger a blocking action on JS side
		// and in that case this will trigger a Flash bug
		// where a new onData is called is a parallel thread
		// ...with the buffer of the previous onData (!)
		s.onData = function( data : String ) {
			sc.__data.queue.add(function() {
				var o = sc.__data.protocol.decodeMessageLength(Bytes.ofStringData(data), 0, data.length);
				if( o.length == null || data.length - o.bytesUsed != o.length - 1 ) {
					sc.__data.error("Invalid message header");
					return;
				}
				sc.processMessage(data.substr(o.bytesUsed, e.data.length-o.bytesUsed));
			});
		};
		#end
		return sc;
	}
}