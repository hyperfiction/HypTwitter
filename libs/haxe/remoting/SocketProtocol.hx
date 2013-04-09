/*
 * Copyright (c) 2005-2007, The haXe Project Contributors
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
import chx.io.StringOutput;
import chx.Serializer;

typedef Socket =
	#if flash9
		flash.net.XMLSocket
	#elseif flash
		flash.XMLSocket
	#elseif js
		js.XMLSocket
	#elseif (neko || php || cpp)
		chx.net.Socket
	#else
		Dynamic
	#end

/**
	The haXe Remoting Socket Protocol is composed of serialized string exchanges.
	Each string is prefixed with a 2-chars header encoding the string size (up to 4KB)
	and postfixed with the \0 message delimiting char.
	A request string is composed of the following serialized values :
		- the boolean true for a request
		- an array of strings representing the object+method path
		- an array of parameters
	A response string is composed of the following serialized values :
		- the boolean false for a response
		- a serialized value representing the result
	Exceptions are serialized with [serializeException] so they will be thrown immediatly
	when they are unserialized.
**/
class SocketProtocol {

	public var socket : Socket;
	public var context : Context;

	public function new( sock, ctx ) {
		this.socket = sock;
		this.context = ctx;
	}

	public function decodeMessageLength( buf : Bytes, pos : Int, len : Int ) : { bytesUsed:Int, length: Null<Int> } {
		var rv = {
			bytesUsed : 0,
			length : null
		}
		if(len < 2) return rv;
		var cnt = (buf.get(pos) & 0xC0) >> 6;
		if(cnt == 0 /*|| (cnt + 1) > len */) return rv;

		var l : Int = 0;
		for(i in 0...cnt) {
			pos++;
			l = (l<<8) | buf.get(pos);
		}
		rv.bytesUsed = 1 + cnt;
		rv.length = l - 1; // 1 was added in encodeMessageLength
		return rv; 
	}

	public function encodeMessageLength( len : Int ) : Array<Int> {
		var a : Array<Int> = new Array();
		len++; // this avoids an embedded null in js strings
		if (len < 256) {
			a[0] = 1 << 6;
			a[1] = len;
		} else if (len < 0x10000) {
			a[0] = 2 << 6;
			a[1] = (len >> 8) & 0xFF;
			a[2] = (len & 0xFF);
		} else if (len < 0x1000000) {
			a[0] = 3 << 6;
			a[1] = (len >> 16) & 0xFF;
			a[2] = (len >> 8) & 0xFF;
			a[3] = (len & 0xFF);
		} else {
			throw "Message is too big";
		}
		return a;
	}

	public function sendRequest( path : Array<String>, params : Array<Dynamic> ) {
		var out : StringOutput = new StringOutput();
		var s = new Serializer(out);
		s.serialize(true);
		s.serialize(path);
		s.serialize(params);
		sendMessage(encodeData(out.toString()));
	}

	public function sendAnswer( answer : Dynamic, ?isException : Bool ) {
		var out : StringOutput = new StringOutput();
		var s = new Serializer(out);
		s.serialize(false);
		if( isException )
			s.serializeException(answer);
		else
			s.serialize(answer);
		sendMessage(encodeData(out.toString()));
	}

	public function sendMessage( msg : String ) {
		var ba = encodeMessageLength(msg.length + 1);
		#if (neko || php || cpp)
		var o = socket.output;
		for(i in 0...ba.length) {
			o.writeByte(ba[i]);
		}
		o.writeString(msg);
		o.writeByte(0);
		o.flush();
		#else
		var s = "";
		for(i in 0...ba.length) {
			s += String.fromCharCode(ba[i]);
		}
		socket.send(s + msg);
		#end
	}

	public dynamic function encodeData( data : String ) : String {
		return data;
	}

	public dynamic function decodeData( data : String ) {
		return data;
	}

	public function isRequest( data : String ) {
		return switch( chx.Unserializer.run(data) ) {
		case true: true;
		case false: false;
		default: throw "Invalid data";
		}
	}

	public function processRequest( data : String, ?onError : Array<String> -> Array<Dynamic> -> Dynamic -> Void ) {
		var s = new chx.Unserializer(data);
		var result : Dynamic;
		var isException = false;
		if( s.unserialize() != true )
			throw "Not a request";
		var path : Array<String> = s.unserialize();
		var args : Array<Dynamic> = s.unserialize();
		try {
			if( context == null ) throw "No context is shared";
			result = context.call(path,args);
		} catch( e : Dynamic ) {
			result = e;
			isException = true;
		}
		// send back result/exception over network
		sendAnswer(result,isException);
		// send the error event
		if( isException && onError != null )
			onError(path,args,result);
	}

	public function processAnswer( data : String ) : Dynamic {
		var s = new chx.Unserializer(data);
		if( s.unserialize() != false )
			throw "Not an answer";
		return s.unserialize();
	}

	#if (neko || php || cpp)
	public function readMessage() {
		var i = socket.input;
		var len:Int = i.readByte();
		if (len & 0xC0 > 0) {
			var count:Int = (len & 0xC0) >> 6;
			len = 0;
			while (count>0) {
				len = (len<<8) | i.readByte();
				count--;
			}
		} else {
			throw "Invalid header";
		}
		len--;
		if(len == 0)
			throw "Invalid length";
		var data = i.readString(len);
		if( i.readByte() != 0 )
			throw "Invalid message";
		return decodeData(data);
	}
	#end

}
