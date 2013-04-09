/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package haxe.remoting;
import haxe.remoting.SocketProtocol.Socket;

/**
 * Flash or JS to server using Socket
 */
class SocketConnection implements AsyncConnection, implements Dynamic<AsyncConnection> {

	var __path : Array<String>;
	var __data : {
		protocol : SocketProtocol,
		results : List<{ onResult : Dynamic -> Void, onError : Dynamic -> Void }>,
		log : Array<String> -> Array<Dynamic> -> Dynamic -> Void,
		error : Dynamic -> Void,
		#if !flash9
		#if (flash || js)
		queue : haxe.TimerQueue,
		#end
		#end
	};

	function new(data,path) {
		__data = data;
		__path = path;
	}

	public function resolve(name) : AsyncConnection {
		var s = new SocketConnection(__data,__path.copy());
		s.__path.push(name);
		return s;
	}

	public function call( params : Array<Dynamic>, ?onResult : Dynamic -> Void ) {
		try {
			__data.protocol.sendRequest(__path,params);
			__data.results.add({ onResult : onResult, onError : __data.error });
		} catch( e : Dynamic ) {
			__data.error(e);
		}
	}

	public function setErrorHandler(h) {
		__data.error = h;
	}

	public function setErrorLogger(h) {
		__data.log = h;
	}

	public function setProtocol( p : SocketProtocol ) {
		__data.protocol = p;
	}

	public function getProtocol() : SocketProtocol {
		return __data.protocol;
	}

	public function close() {
		try __data.protocol.socket.close() catch( e : Dynamic ) { };
	}

	public function processMessage( data : String ) {
		var request;
		var proto = __data.protocol;
		data = proto.decodeData(data);
		try {
			request = proto.isRequest(data);
		} catch( e : Dynamic ) {
			var msg = Std.string(e) + " (in "+StringTools.urlEncode(data)+")";
			__data.error(msg); // protocol error
			return;
		}
		// request
		if( request ) {
			try proto.processRequest(data,__data.log) catch( e : Dynamic ) __data.error(e);
			return;
		}
		// answer
		var f = __data.results.pop();
		if( f == null ) {
			__data.error("No response expected ("+data+")");
			return;
		}
		var ret;
		try {
			ret = proto.processAnswer(data);
		} catch( e : Dynamic ) {
			f.onError(e);
			return;
		}
		if( f.onResult != null ) f.onResult(ret);
	}

	#if (flash || js || neko)

	function defaultLog(path,args,e) {
		// exception inside the called method
		var astr, estr;
		try astr = args.join(",") catch( e : Dynamic ) astr = "???";
		try estr = Std.string(e) catch( e : Dynamic ) estr = "???";
		var header = "Error in call to "+path.join(".")+"("+astr+") : ";
		__data.error(header + estr);
	}

	/**
	 * Creates remoting communications over an remoting Socket. In neko,
	 * this can be used for real time communications with a Flash client which 
	 * is using an XMLSocket to connect to the server.
	 * @param	s
	 * @param	?ctx
	 */
	public static function create( s : Socket, ?ctx : Context ) {
		var data = {
			protocol : new SocketProtocol(s,ctx),
			results : new List(),
			error : function(e) throw e,
			log : null,
			#if !flash9
			#if (flash || js)
			queue : new haxe.TimerQueue(),
			#end
			#end
		};
		var sc = new SocketConnection(data,[]);
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

	#end

}
