package chx.net.io;

import chx.io.Output;
import chx.lang.BlockedException;
import chx.lang.IOException;

#if (neko || cpp)

class TcpSocketOutput extends chx.io.Output {

	var __handle : Void;

	public function new(s) {
		__handle = s;
	}

	public override function writeByte( c : Int ) : Output {
		try {
			socket_send_char(__handle, c);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw new BlockedException();
			else
				throw new IOException("unhandled", e);
		}
		return this;
	}

	public override function writeBytes( buf : Bytes, pos : Int, len : Int) : Int {
		return try {
			socket_send(__handle, buf.getData(), pos, len);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw new BlockedException();
			else
				throw new IOException("unhandled", e);
		}
	}

	public override function close() {
		super.close();
		if( __handle != null ) socket_close(__handle);
	}

	private static var socket_close = chx.Lib.load("std","socket_close",1);
	private static var socket_send_char = chx.Lib.load("std","socket_send_char",2);
	private static var socket_send = chx.Lib.load("std","socket_send",4);
}

#elseif flash9

import flash.errors.IOError;

class TcpSocketOutput extends chx.io.Output {
	var __handle : flash.net.Socket;

	public function new(s) {
		__handle = cast s;
	}

	public override function writeByte( c : Int ) : Output {
		try {
			__handle.writeByte(c);
		} catch( e : IOError ) {
			throw new IOException("unhandled", e);
		}
		return this;
	}

	public override function writeBytes( buf : Bytes, pos : Int, len : Int) : Int {
		try {
			__handle.writeBytes(buf.getData(), pos, len);
		} catch( e : IOError ) {
			throw new IOException("unhandled", e);
		}
		return len;
	}

	public override function close() {
		super.close();
		if( __handle != null )
			try __handle.close() catch(e:Dynamic) {};
	}

	public override function flush() : Output {
		__handle.flush();
		return this;
	}

	override function setEndian(b) {
		bigEndian = b;
		__handle.endian = b ? flash.utils.Endian.BIG_ENDIAN : flash.utils.Endian.LITTLE_ENDIAN;
		return b;
	}
}

#end
