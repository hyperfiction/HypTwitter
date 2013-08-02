/*
 * Copyright (c) 2005-2008, The haXe Project Contributors
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
package chx.io;

import chx.io.BytesInput;
import chx.lang.OverflowException;
import chx.lang.BlockedException;
import chx.lang.OutsideBoundsException;
import chx.lang.EofException;

/**
	An Input is an abstract reader. See other classes in the [chx.io] package
	for several possible implementations.
**/
class Input {
	/**
		Returns number of bytes available to be read without blocking.
	**/
	public var bytesAvailable(__getBytesAvailable, null) : Int;
	public var bigEndian(default,__setEndian) : Bool;

	/**
		Abstract method for reading an unsigned 8 bit value from the
		input stream. For a signed value, use readInt8.
	**/
	public function readByte() : Int {	
		#if cpp
			throw new chx.lang.FatalException("Not implemented");
			return 0;
		#else
			return throw new chx.lang.FatalException("Not implemented");
		#end
	}

	/**
		Reads up to len bytes from the input buffer, returning the number of
		bytes that were actually available to read
	**/
	public function readBytes( s : Bytes, pos, len ) : Int {
		var k = len;
		var b = s.getData();
		if( pos < 0 || len < 0 || pos + len > s.length )
			throw new OutsideBoundsException();
		while( k > 0 ) {
			#if neko
				untyped __dollar__sset(b,pos,readByte());
			#elseif php
				b[pos] = untyped __call__("chr", readByte());
			#elseif cpp
				b[pos] = untyped readByte();
			#else
				b[pos] = readByte();
			#end
			pos++;
			k--;
		}
		return len;
	}
	
	/**
	* Returns true if the Input is at the end of file.
	**/
	public function isEof() : Bool {
		return throw new chx.lang.UnsupportedException("Not implemented for this input type");
	}

	public function close() {
	}
	
	public function readAll( ?bufsize : Int ) : Bytes {
		if( bufsize == null )
		#if php
			bufsize = 8192; // default value for PHP and max under certain circumstances
		#else
			bufsize = (1 << 14); // 16 Ko
		#end
		var buf = Bytes.alloc(bufsize);
		var total = new BytesBuffer();
		try {
			while( true ) {
				var len = readBytes(buf,0,bufsize);
				if( len == 0 )
					throw new BlockedException();
				total.addBytes(buf,0,len);
			}
		} catch( e : EofException ) {
		}
		return total.getBytes();
	}

	/**
		Reads len bytes. Will continue to loop calling readBytes until the requested
		number of bytes is read.
	**/
	public function readFullBytes( s : Bytes, pos : Int, len : Int ) : Void {
		while( len > 0 ) {
			var k = readBytes(s,pos,len);
			pos += k;
			len -= k;
		}
	}

	/**
		Reads nbytes from the input stream, by calling readBytes until nbytes is reached
	**/
	public function read( nbytes : Int ) : Bytes {
		var s = Bytes.alloc(nbytes);
		var p = 0;
		while( nbytes > 0 ) {
			var k = readBytes(s,p,nbytes);
			if( k == 0 ) throw new BlockedException();
			p += k;
			nbytes -= k;
		}
		return s;
	}

	/**
		Reads from input until the unsigned int8 value 'end' is reached.
	**/
	public function readUntil( end : Int ) : String {
		var buf = new StringBuf();
		var last : Int;
		while( (last = readByte()) != end )
			buf.addChar( last );
		return buf.toString();
	}

	/**
		Reads from input until an \n or \r\n sequence is reached.
	**/
	public function readLine() : String {
		var buf = new StringBuf();
		var last : Int;
		var s;
		try {
			while( (last = readByte()) != 10 )
				buf.addChar( last );
			s = buf.toString();
			if( s.charCodeAt(s.length-1) == 13 ) s = s.substr(0,-1);
		} catch( e : EofException ) {
			s = buf.toString();
			if( s.length == 0 )
				#if neko chx.Lib.rethrow #else throw #end (e);
		}
		return s;
	}

	public function readFloat() : Float {
		#if neko
			return _float_of_bytes(untyped read(4).b, bigEndian);
		#elseif cpp
			return _float_of_bytes(read(4).getData(),bigEndian);
		#elseif php
			var a = untyped __call__('unpack', 'f', readString(4));
			return a[1];
		#elseif flash9
			var bi = new BytesInput(read(4));
			bi.bigEndian = this.bigEndian;
			return bi.readFloat();
		#else
			return math.IEEE754.bytesToFloat(read(4), bigEndian);
		#end
	}

	public function readDouble() : Float {
		#if neko
			return _double_of_bytes(untyped read(8).b, bigEndian);
		#elseif cpp
			return _double_of_bytes(read(8).getData(),bigEndian);
		#elseif php
			var a = untyped __call__('unpack', 'd', readString(8));
			return a[1];
		#elseif flash9
			var bi = new BytesInput(read(8));
			bi.bigEndian = this.bigEndian;
			return bi.readDouble();
		#else
			return math.IEEE754.bytesToFloat(read(8), bigEndian);
		#end
	}

	/**
		Read a single byte as a signed Int (-128 to +128).
	**/
	public function readInt8() : Int {
		var n = readByte();
		if( n >= 128 )
			return n - 256;
		return n;
	}

	/**
	* Read an unsigned 8 bit value. Same as readByte
	**/
	public inline function readUInt8() : Int {
		return readByte();
	}

	/**
		Reads 2 bytes, returning a signed Int
	**/
	public function readInt16() : Int {
		var ch1 = readByte();
		var ch2 = readByte();
		var n = bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
		if( n & 0x8000 != 0 )
			return n - 0x10000;
		return n;
	}

	/**
		Reads 2 bytes, returning an unsigned Int
	**/
	public function readUInt16() : Int {
		var ch1 = readByte();
		var ch2 = readByte();
		return bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
	}

	/**
		Reads 3 bytes, returning a signed Int
	**/
	public function readInt24() : Int {
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		var n = bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
		if( n & 0x800000 != 0 )
			return n - 0x1000000;
		return n;
	}

	/**
		Reads 3 bytes, returning an unsigned Int
	**/
	public function readUInt24() : Int {
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		return bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
	}

	/**
		Reads 4 bytes, returning a signed Int
	**/
	public function readInt31() : Int {
		var ch1,ch2,ch3,ch4;
		if( bigEndian ) {
			ch4 = readByte();
			ch3 = readByte();
			ch2 = readByte();
			ch1 = readByte();
		} else {
			ch1 = readByte();
			ch2 = readByte();
			ch3 = readByte();
			ch4 = readByte();
		}
		if( ((ch4 & 128) == 0) != ((ch4 & 64) == 0) ) throw new OverflowException();
		return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

	/**
		Reads 4 bytes, returning an unsigned Int
	**/
	public function readUInt30() : Int {
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		var ch4 = readByte();
		if( (bigEndian?ch1:ch4) >= 64 ) throw new OverflowException();
		return bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

	/**
		Reads 4 bytes, returning a signed Int32
	**/
	public function readInt32() : haxe.Int32 {
		var ch1 = readByte();
		var ch2 = readByte();
		var ch3 = readByte();
		var ch4 = readByte();
		return bigEndian ? haxe.Int32.make((ch1 << 8) | ch2,(ch3 << 8) | ch4) : haxe.Int32.make((ch4 << 8) | ch3,(ch2 << 8) | ch1);
	}

	/**
		Reads len bytes as a string
	**/
	public function readString( len : Int ) : String {
		var b = Bytes.alloc(len);
		readFullBytes(b,0,len);
		#if neko
		return chx.Lib.stringReference(b);
		#else
		return b.toString();
		#end
	}

	/**
	* Reads a 16 bit unsigned int length value, then the string.
	*
	* @return String encoded with length from stream
	**/
	public function readUTF() : String {
		var len = readUInt16();
		return readString(len);
	}

	/**
	 * Read from the buffer using the specified multibyte char set.
	 * @todo Lots.
	 **/
	public function readMultiByteString(len : Int, charset:String) : String {
		var cset = charset.toLowerCase();
		switch(cset) {
		case "latin1":
		case "us-ascii":
		default:
			throw new chx.lang.UnsupportedException(cset+" not supported");
		}
		return readString(len);
	}

	//////////////////////////////////////////////////
	//               Getters/Setters                //
	//////////////////////////////////////////////////

	function __getBytesAvailable() : Int {
		return throw new chx.lang.FatalException("Not implemented");
	}

	function __setEndian(b) {
		bigEndian = b;
		return b;
	}

#if (neko || cpp)
	static var _float_of_bytes = chx.Lib.load("std","float_of_bytes",2);
	static var _double_of_bytes = chx.Lib.load("std","double_of_bytes",2);
	#if neko
	static function __init__() untyped {
		Input.prototype.bigEndian = false;
	}
	#end
#end
}
