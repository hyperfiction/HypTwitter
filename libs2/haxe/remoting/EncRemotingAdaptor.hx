/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package haxe.remoting;
import Type;
import haxe.remoting.SocketConnection;
import haxe.remoting.SocketProtocol;
import crypt.IMode;

/**
	An encrypted version of Haxe remoting.
**/
class EncRemotingAdaptor {
	public var sc(default,null) : SocketConnection;
	var sp : SocketProtocol;
	var cipherMode : IMode;

	public function new(sc : SocketConnection) {
		this.sc = sc;
		this.sp = sc.getProtocol();
		var me = this;

		// SocketProtocol overrides
		//sp.processRequest = me.processRequest;
		sp.sendAnswer = me.sendAnswer;
	}

	//////////////////////////////
	//  Encryption support      //
	//////////////////////////////
	/**
		Begin encryption on the remoting connection.
	**/
	public function startCrypt(cipherMode : crypt.IMode) {
		this.cipherMode = cipherMode;

		// output side, override SocketProtocol.sendMessage
		sp.sendMessage = sendMessageEnc;

		// input side, add a crypt.IMode object to the socket
		// in SocketConnection.getProtocol().socket
		Reflect.setField(
			sp.socket,"__crypt",
			cipherMode);
	}

	/**
		Returns true if the connection is currently being encrypted
	**/
	public function isCrypted() : Bool {
		return Reflect.hasField(sp.socket, "__crypt");
	}

	/**
		Check if any given SocketConnection is crypted
	**/
	public static function isCryptedConnection(cnx : SocketConnection) : Bool {
		return Reflect.hasField(cnx.getProtocol().socket, "__crypt");
	}

	static function encMsgLength( c1 : Null<Int>, c2 : Null<Int> ) : Null<Int> {
		if( c1 == null || c2 == null)
			return null;
		return (c1 << 8) | c2;
	}

	//////////////////////////////
	// SocketProtocol Overrides //
	//////////////////////////////

	public function sendAnswer( answer : Dynamic, ?isException : Bool ) {
		if(!isCrypted() &&
			Type.typeof(answer) == TNull &&
			!isException)
				return;
		var s = new haxe.Serializer();
		s.serialize(false);
		if( isException )
			s.serializeException(answer);
		else
			s.serialize(answer);
		sp.sendMessage(s.toString());
	}

	function sendMessageEnc( msg : String ) {
		var e = sp.encodeMessageLength(msg.length + 3);
		var sb = new StringBuf();
#if CRYPT_DEBUG_PROTOCOL
		trace(msg + " length is "+(msg.length + 3));
		trace(e.c1);
		trace(e.c2);
#end
		sb.add(Std.chr(e.c1));
		sb.add(Std.chr(e.c2));
		sb.add(msg);
		sb.add(Std.chr(0));
#if CRYPT_DEBUG_PROTOCOL
		trace(StringTools.baseEncode(sb.toString(), Constants.DIGITS_HEXL));
#end

		var enc = cipherMode.encrypt(sb.toString());
		var len = enc.length + 2;
		if(len > 0xFFFF)
			throw "Message too long";
		var c1 = len>>8 & 0xFF;
		var c2 = len & 0xFF;

		var sbenc = new StringBuf();
		sbenc.add(Std.chr(c1));
		sbenc.add(Std.chr(c2));
		sbenc.add(enc);
#if CRYPT_DEBUG_PROTOCOL
		trace(len);
		trace(c1);
		trace(c2);
		trace(StringTools.baseEncode(enc, Constants.DIGITS_HEXL));
		trace(StringTools.baseEncode(sbenc.toString(), Constants.DIGITS_HEXL));
#end
		#if neko
		try {
			sp.socket.output.write(sbenc.toString());
		}
		catch(e:Dynamic) {
			trace(e);
			chx.Lib.rethrow(e);
		}
		#else true
		sp.socket.send(sbenc.toString());
		#end
	}

	// For EncThrRemotingServer and clients?
	public static function readClientMessage( cnx : haxe.remoting.SocketConnection, buf : String, pos : Int, len : Int ) {
		if(!isCryptedConnection(cnx)) {
		//if(! Reflect.hasField(cnx.getProtocol().socket, "__crypt") ) {
#if CRYPT_DEBUG_PROTOCOL
			trace("No encryption mode");
#end
			return readRemotingMessage( cnx, buf, pos, len );
		}

#if CRYPT_DEBUG_PROTOCOL
		trace("Encrypted mode");
#end
		var aes : crypt.IMode = (cast cnx.getProtocol().socket).__crypt;
		var eMsgLen = encMsgLength(buf.charCodeAt(pos),buf.charCodeAt(pos+1));
		if(eMsgLen == null)
			return null;
		if(len < eMsgLen)
			return null;
		var dec :String;
		try {
#if CRYPT_DEBUG_PROTOCOL
			trace(aes);
#end
			dec = aes.decrypt(buf.substr(pos+2,eMsgLen-2));
		}
		catch(e : Dynamic) {
			throw(e);
		}
		var m = readRemotingMessage( cnx, dec, 0, dec.length );
		m.bytes = eMsgLen;
		return m;
	}

	static function readRemotingMessage( cnx : SocketConnection, buf : String, pos : Int, len : Int ) {
		var msgLen = cnx.getProtocol().messageLength(buf.charCodeAt(pos),buf.charCodeAt(pos+1));
#if neko
		if( msgLen == null ) {

			if( buf.charCodeAt(pos) != 60 )
				throw "Invalid remoting message '"+buf.substr(pos,len)+"'";
			// XML handling
			var p = buf.indexOf("\\0",pos);
			if( p == -1 )
				return null;
			return {
				msg : buf.substr(pos,p-pos),
				bytes : p - pos + 1,
			};

		}
		if( len < msgLen )
			return null;
		if( buf.charCodeAt(pos + msgLen-1) != 0 )
			throw "Truncated message";
		return {
			msg : buf.substr(pos+2,msgLen-3),
			bytes : msgLen,
		};
#else (flash || js)
		if(msgLen == null || len != msgLen -1) {
			untyped cnx.__error.ref("Invalid message header");
			return null;
		}
		return {
			msg : buf.substr(2,len-2),
			bytes : msgLen,
		};
#end
	}

#if (flash || js)
	/**
		To use the adaptor, instead of using SocketConnection.socketConnect,
		this function must be called.
	**/
	static public function flashJsSocketConnect( s : Socket ) {
		var sc = untyped { new SocketConnection(new SocketProtocol(s), []); }
		Reflect.setField(sc,"__funs",new List<Dynamic -> Void>());

		#if flash9
		var f = function( scnx : SocketConnection, e : flash.events.DataEvent) {
			var data = e.data;
			var m = readClientMessage( scnx, e.data, 0, e.data.length );
			if(m == null)
				return;
			scnx.processMessage(m.msg);
		}
		s.addEventListener(flash.events.DataEvent.DATA, callback(f,sc));

		#else true
		var f = function( scnx : SocketConnection) {
		}
		s.onData = function(data : String) {
			haxe.Timer.queue(function() {
				var m = readClientMessage(sc,data,0,data.length);
				if(m == null)
					return;
				sc.processMessage(m.msg);
			});
		};
		#end
		return sc;
	}
#end
}
