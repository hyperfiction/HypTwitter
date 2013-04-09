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

import chx.lang.EofException;
import chx.lang.OutsideBoundsException;
import chx.lang.OverflowException;

class BytesInput extends Input {
	public var position(getPosition, setPosition) : Int;
	var b : chx.io.BytesData;
	#if !flash9
	var pos : Int;
	var len : Int;
	#end

	public function new( b : Bytes, pos : Int=0, len : Null<Int>=null ) {
		if( len == null ) len = b.length - pos;
		if( pos < 0 || len < 0 || pos + len > b.length ) throw new OutsideBoundsException();
		#if flash9
		var ba = b.getData();
		ba.position = pos;
		if( len != ba.bytesAvailable ) {
			// truncate
			this.b = new flash.utils.ByteArray();
			ba.readBytes(this.b,0,len);
		} else
			this.b = ba;
		this.b.endian = flash.utils.Endian.LITTLE_ENDIAN;
		#else
		this.b = b.getData();
		this.pos = pos;
		this.len = len;
		#end
		bigEndian = false;
	}

	/**
	 * Returns a copy of the underlying Bytes object
	 **/
	public function getBytesCopy() : Bytes {
		var orig = position;
		var rv : Bytes = null;
		#if neko
		rv = try Bytes.ofData(untyped __dollar__ssub(b,0,len)) catch( e : Dynamic ) throw new OutsideBoundsException();
		#elseif flash9
		//b.position = pos;
		var b2 = new flash.utils.ByteArray();
		b.readBytes(b2,0,b.length);
		rv = Bytes.ofData(b2);
		#elseif php
		rv = Bytes.ofData(untyped __call__("substr", b, 0, len));
		#else // js and php
		rv = Bytes.ofData(b.slice(0,b.length));
		#end
		position = orig;
		return rv;
	}

	override public function readByte() : Int {
		#if flash9
			return try b.readUnsignedByte() catch( e : Dynamic ) throw new EofException();
		#else
			if( this.len == 0 )
				throw new EofException();
			len--;
			#if neko
			return untyped __dollar__sget(b,pos++);
			#elseif php
			return untyped __call__("ord", b[pos++]);
			#elseif cpp
			return untyped b[pos++];
			#else
			return b[pos++];
			#end
		#end
	}

	override public function readBytes( buf : Bytes, pos, len ) : Int {
		#if !neko
			if( pos < 0 || len < 0 || pos + len > buf.length )
				throw new OutsideBoundsException();
		#end
		#if flash9
			var l : UInt = len;
			if( l > b.bytesAvailable && b.bytesAvailable > 0 ) len = b.bytesAvailable;
			try b.readBytes(buf.getData(),pos,len) catch( e : Dynamic ) throw new EofException();
		#else
			if( this.len == 0 && len > 0 )
				throw new EofException();
			if( this.len < len )
				len = this.len;
			#if neko
			try untyped __dollar__sblit(buf.getData(),pos,b,this.pos,len) catch( e : Dynamic ) throw new OutsideBoundsException();
			#elseif php
			untyped __php__("$buf->b = substr($buf->b, 0, $pos) . substr($this->b, $this->pos, $len) . substr($buf->b, $pos+$len)");
			#else
			var b1 = b;
			var b2 = buf.getData();
			for( i in 0...len )
				b2[pos+i] = b1[this.pos+i];
			#end
			this.pos += len;
			this.len -= len;
		#end
		return len;
	}

	override function __getBytesAvailable() : Int {
		#if flash9
			return b.bytesAvailable;
		#else
			//var r = len - pos;
			return len >= 0 ? len : 0;
		#end
	}

	/**
	* Returns the unsigned byte at the current or alternate position, without changing
	* the position of the input stream.
	* @param pos A position in the stream, or null for current position
	**/
	public function peek(pos:Null<Int> = null) : Int {
		if(pos == null)
			pos = getPosition();
		var orig = getPosition();
		setPosition(pos);
		var d = readByte();
		setPosition(orig);
		return d;
	}

	public function setPosition(p:Int) : Int {
		#if flash9
			b.position = p;
		#else
			len = len + (getPosition() - p);
			pos = p;
		#end
		return p;
	}

	public function getPosition() : Int {
		#if flash9
			return b.position;
		#else
			return pos;
		#end
	}


	#if flash9
	override function __setEndian(e) {
		bigEndian = e;
		b.endian = e ? flash.utils.Endian.BIG_ENDIAN : flash.utils.Endian.LITTLE_ENDIAN;
		return e;
	}

	override public function readFloat() {
		return try b.readFloat() catch( e : Dynamic ) throw new EofException();
	}

	override public function readDouble() {
		return try b.readDouble() catch( e : Dynamic ) throw new EofException();
	}

	override public function readInt8() {
		return try b.readByte() catch( e : Dynamic ) throw new EofException();
	}

	override public function readInt16() {
		return try b.readShort() catch( e : Dynamic ) throw new EofException();
	}

	override public function readUInt16() : Int {
		return try b.readUnsignedShort() catch( e : Dynamic ) throw new EofException();
	}

	override public function readInt31() {
		var n;
		try n = b.readInt() catch( e : Dynamic ) throw new EofException();
		if( (n >>> 30) & 1 != (n >>> 31) ) throw new OverflowException();
		return n;
	}

	override public function readUInt30() {
		var n;
		try n = b.readInt() catch( e : Dynamic ) throw new EofException();
		if( (n >>> 30) != 0 ) throw new OverflowException();
		return n;
	}

	override public function readInt32() : haxe.Int32 {
		return try cast b.readInt() catch( e : Dynamic ) throw new EofException();
	}

	override public function readString( len : Int ) {
		return try b.readUTFBytes(len) catch( e : Dynamic ) throw new EofException();
	}

	#end

}
