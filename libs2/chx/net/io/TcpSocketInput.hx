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

package chx.net.io;

import chx.lang.Exception;
import chx.lang.EofException;
import chx.lang.BlockedException;
import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;


#if (neko || cpp)
class TcpSocketInput extends chx.io.Input {

	var __handle : Void;

	public function new(s) {
		__handle = s;
	}

	public override function readByte() {
		return try {
			socket_recv_char(__handle);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw new BlockedException();
			else if( __handle == null )
				throw new Exception("unhandled", e);
			else
				throw new chx.lang.EofException();
		}
	}

	override function __getBytesAvailable() : Int {
		return throw new chx.lang.FatalException("Not implemented");
	}

	public override function readBytes( buf : Bytes, pos : Int, len : Int ) : Int {
		var r;
		try {
			r = socket_recv(__handle,buf.getData(),pos,len);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw new BlockedException();
			else
				throw new Exception("Client socket in shutdown state", e);
		}
		if( r == 0 )
			throw new EofException();
		return r;
	}

	public override function close() {
		super.close();
		if( __handle != null ) socket_close(__handle);
	}

	private static var socket_recv = chx.Lib.load("std","socket_recv",4);
	private static var socket_recv_char = chx.Lib.load("std","socket_recv_char",1);
	private static var socket_close = chx.Lib.load("std","socket_close",1);
}

#elseif flash9

class TcpSocketInput extends chx.io.Input {
	var __handle : flash.net.Socket;

	public function new(s : flash.net.Socket) {
		__handle = s;
	}

	override function __setEndian(b) {
		bigEndian = b;
		__handle.endian = b ? flash.utils.Endian.BIG_ENDIAN : flash.utils.Endian.LITTLE_ENDIAN;
		return b;
	}

	public override function readByte() {
		return try {
			cast __handle.readUnsignedByte();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	override function __getBytesAvailable() : Int {
		return __handle.bytesAvailable;
	}

	public override function readBytes(s : Bytes, pos : Int, len : Int ) : Int {
		if( pos < 0 || len < 0 || pos + len > s.length )
			throw new OutsideBoundsException();
		var b = s.getData();
		var ba = __handle.bytesAvailable;
		if(ba == 0) return 0;
		if(len > ba)
			len = ba;
 		try {
			__handle.readBytes(b, pos, len);
			return len;
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	public override function close() {
		super.close();
		if( __handle != null ) __handle.close();
	}

	public override function readDouble() : Float {
		return try {
			__handle.readDouble();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	public override function readFloat() : Float {
		return try {
			__handle.readFloat();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	public override function readInt16() : Int {
		return try {
			__handle.readShort();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	public override function readUInt16() : Int {
		return try {
			__handle.readUnsignedShort();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}

	public override function readInt31() : Int {
		var v = try {
			__handle.readInt();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
		if( ((v & 0x800000) == 0) != ((v & 0x400000) == 0) )
			throw new OverflowException();
		return v;
	}

	public override function readUInt30() {
		var v = try {
			__handle.readUnsignedInt();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
		if( v >= 0x40000000)
			throw new OverflowException();
		return cast v;
	}

	public override function readInt32() : haxe.Int32 {
		return try {
			cast __handle.readInt();
		}
		catch( e : flash.errors.EOFError ) {
			throw new BlockedException();
		}
		catch( e : flash.errors.IOError ) {
			throw new EofException();
		}
		catch( e : Dynamic ) {
			throw new Exception("unhandled", e);
		}
	}
}

#end
