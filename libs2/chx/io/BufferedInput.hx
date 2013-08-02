/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

package chx.io;

import Bytes;
import BytesBuffer;
import chx.io.Input;

import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;
import chx.lang.EofException;

/**
	An Input reader that buffers reading of multi-byte data types.
**/
class BufferedInput extends FilteredInput {
	var buf : BytesBuffer;

	public function new(input:Input) {
		super(input);
		buf = new BytesBuffer();
	}

	/**
		Resets current buffer, saving anything after the specified bytes that were consumed.
	**/
	function consumed(c:Int) : Void {
		var r = newBuffer();
		if(r.length <= c || r.length == 0)
			return;
		buf.addBytes(r, c, r.length-c);
	}

	/**
		Resets the current buffer, returning the original contents
	**/
	function newBuffer() : Bytes {
		var bytes = buf.getBytes();
		buf = new BytesBuffer();
		return bytes;
	}

	/**
		Calls readByte(), but buffers the returned byte. After successfully
		consuming, a call to newBuffer should be made.
	**/
	inline function bufferByte() : Int {
		var b = input.readByte();
		buf.addByte(b);
		return b;
	}

	/**
		Will return bytes from the current buffer until the specified end
		byte, or null if the current buffer does not contain the end byte
	**/
	function readBufferUntil(end : Int) : Bytes {
		var bb = new BytesBuffer();
		var last : Null<Int> = null;
		var r = newBuffer();
		var pos = 0;
		while(pos < r.length && (last = r.get(pos)) != end) {
			bb.addByte( last );
			pos ++;
		}
		if(last != null && last == end ) {
			if(pos < r.length)
				buf.addBytes(r, pos, r.length - pos);
			return bb.getBytes();
		}
		buf.addBytes(r, 0, r.length);
		return null;
	}

	/*
	public override function readBytes( s : Bytes, pos : Int, len : Int ) : Int {

		var b = s.getData();
		if( pos < 0 || len < 0 || pos + len > s.length )
			throw new OutsideBoundsException();

		var r = newBuffer();
		var k = len - r.length;
		if(k < 0) {
			buf.addBytes(r, r.length + k, 0 - k);
		}
		else {
			buf.addBytes(r, 0, r.length);
			while( k > 0 ) {
				bufferByte();
				k--;
			}
		}

		k = 0;
		r = newBuffer();
		while( k < len ) {
			#if neko
				untyped __dollar__sset(b,pos,r.get(k));
			#else
				b[pos] = r.get(k);
			#end
			pos++;
		}
		return len;
	}
	*/

	/**
		Reads from input until the unsigned int8 value 'end' is reached.
	**/
	public override function readUntil( end : Int ) : String {
		var res = readBufferUntil(end);
		if(res != null)
			return res.toString();
		var last : Int;
		while( (last = bufferByte()) != end ) {}
		return newBuffer().toString();
	}

	/**
		Reads from input until an \n or \r\n sequence is reached.
	**/
	public override function readLine() : String {
		var res = readBufferUntil(10);
		if(res != null)
			return res.toString();

		var s : String;
		try {
			var last : Int;
			while( (last = bufferByte()) != 10 ) {}
			s = newBuffer().toString();
			if( s.charCodeAt(s.length-1) == 13 ) s = s.substr(0,-1);
		} catch( e : EofException ) {
			s = newBuffer().toString();
			if( s.length == 0 )
				#if neko chx.Lib.rethrow #else throw #end (e);
		}
		return s;
	}

	public override function readInt16() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		consumed(2);
		var n = bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
		if( n & 0x8000 != 0 )
			return n - 0x10000;
		return n;
	}

	public override function readUInt16() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		consumed(2);
		return bigEndian ? ch2 | (ch1 << 8) : ch1 | (ch2 << 8);
	}

	public override function readInt24() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		var ch3 = if(r.length > 2) r.get(2) else bufferByte();
		consumed(3);
		var n = bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
		if( n & 0x800000 != 0 )
			return n - 0x1000000;
		return n;
	}

	public override function readUInt24() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		var ch3 = if(r.length > 2) r.get(2) else bufferByte();
		consumed(3);
		return bigEndian ? ch3 | (ch2 << 8) | (ch1 << 16) : ch1 | (ch2 << 8) | (ch3 << 16);
	}

	public override function readInt31() {
		var ch1,ch2,ch3,ch4;
		if( bigEndian ) {
			var r = newBuffer();
			ch4 = if(r.length > 0) r.get(0) else bufferByte();
			ch3 = if(r.length > 1) r.get(1) else bufferByte();
			ch2 = if(r.length > 2) r.get(2) else bufferByte();
			ch1 = if(r.length > 3) r.get(3) else bufferByte();
		} else {
			var r = newBuffer();
			ch1 = if(r.length > 0) r.get(0) else bufferByte();
			ch2 = if(r.length > 1) r.get(1) else bufferByte();
			ch3 = if(r.length > 2) r.get(2) else bufferByte();
			ch4 = if(r.length > 3) r.get(3) else bufferByte();
		}
		consumed(4);
		if( ((ch4 & 128) == 0) != ((ch4 & 64) == 0) ) throw new OverflowException();
		return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

	public override function readUInt30() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		var ch3 = if(r.length > 2) r.get(2) else bufferByte();
		var ch4 = if(r.length > 3) r.get(3) else bufferByte();
		consumed(4);
		if( (bigEndian?ch1:ch4) >= 64 ) throw new OverflowException();
		return bigEndian ? ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24) : ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
	}

	public override function readInt32() {
		var r = newBuffer();
		var ch1 = if(r.length > 0) r.get(0) else bufferByte();
		var ch2 = if(r.length > 1) r.get(1) else bufferByte();
		var ch3 = if(r.length > 2) r.get(2) else bufferByte();
		var ch4 = if(r.length > 3) r.get(3) else bufferByte();
		consumed(4);
		return bigEndian ? haxe.Int32.make((ch1 << 8) | ch2,(ch3 << 8) | ch4) : haxe.Int32.make((ch4 << 8) | ch3,(ch2 << 8) | ch1);
	}

#if neko
	static var _float_of_bytes = chx.Lib.load("std","float_of_bytes",2);
	static var _double_of_bytes = chx.Lib.load("std","double_of_bytes",2);
	static function __init__() untyped {
		BufferedInput.prototype.bigEndian = false;
	}
#end

}
