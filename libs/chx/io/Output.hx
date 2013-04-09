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

import chx.io.BytesOutput;
import chx.lang.BlockedException;
import chx.lang.OverflowException;
import chx.lang.OutsideBoundsException;
import chx.lang.EofException;
import chx.text.Sprintf;
import chx.vm.Lock;

/**
	An Output is an abstract writer. A specific output implementation will only
	have to override the [writeChar] and maybe the [write], [flush] and [close]
	methods.
**/
class Output {

	public var bigEndian(default,setBigEndian) : Bool;
	/** A chx.vm.Lock may be added to the Output and available for use **/
	public var lock : Lock;

	/**
		Write a single byte (Unsigned Int 8) to the output
		@throws chx.lang.IOException on error
	**/
	public function writeByte( c : Int ) : Output {
		return throw new chx.lang.FatalException("Not implemented");
	}

	public function writeBytes( s : Bytes, pos : Int, len : Int ) : Int {
		var k = len;
		var b = s.getData();
		#if !neko
		if( pos < 0 || len < 0 || pos + len > s.length )
			throw new OutsideBoundsException();
		#end
		while( k > 0 ) {
			#if neko
				writeByte(untyped __dollar__sget(b,pos));
			#elseif php
				writeByte(untyped __call__("ord", b[pos]));
			#elseif cpp
				writeByte(untyped b[pos]);
			#else
				writeByte(b[pos]);
			#end
			pos++;
			k--;
		}
		return len;
	}

	public function flush() : Output {
		return this;
	}

	public function close() : Void {
	}

	function setBigEndian( b ) : Bool {
		bigEndian = b;
		return b;
	}

	/* ------------------ API ------------------ */

	/**
		Write the content of a Bytes to the output stream.
		@throws chx.lang.BlockedException when output blocks.
	**/
	public function write( b : Bytes ) : Output {
		var l = b.length;
		var p = 0;
		while( l > 0 ) {
			var k = writeBytes(b, p, l);
			if( k == 0 ) throw new BlockedException();
			p += k;
			l -= k;
		}
		return this;
	}

	public function writeFullBytes( s : Bytes, pos : Int, len : Int ) : Output {
		while( len > 0 ) {
			var k = writeBytes(s,pos,len);
			pos += k;
			len -= k;
		}
		return this;
	}

	/**
		Writes an 8 digit precision Float to the output
	**/
	public function writeFloat( x : Float ) : Output {
		#if neko
			write(untyped new Bytes(4,_float_bytes(x,bigEndian)));
		#elseif cpp
			write(Bytes.ofData(_float_bytes(x,bigEndian)));
		#elseif php
			write(untyped Bytes.ofString(__call__('pack', 'f', x)));
		#elseif flash9
			var bo = new BytesOutput();
			bo.bigEndian = this.bigEndian;
			bo.writeFloat(x);
			write(bo.getBytes());
		#else
			write(math.IEEE754.floatToBytes(x, bigEndian));
		#end
		return this;
	}

	/**
		Write a 16 digit precision Float to the output
	**/
	public function writeDouble( x : Float ) : Output {
		#if neko
			write(untyped new Bytes(8,_double_bytes(x,bigEndian)));
		#elseif cpp
			write(Bytes.ofData(_double_bytes(x,bigEndian)));
		#elseif php
			write(untyped Bytes.ofString(__call__('pack', 'd', x)));
		#elseif flash9
			var bo = new BytesOutput();
			bo.bigEndian = this.bigEndian;
			bo.writeDouble(x);
			write(bo.getBytes());
		#else
			write(math.IEEE754.doubleToBytes(x, bigEndian));
		#end
		return this;
	}

	/**
	 * Write a signed 8 bit integer
	 * @throws chx.lang.OverflowException if value has too many bits.
	 **/
	public function writeInt8( x : Int ) : Output {
		if( x < -0x80 || x >= 0x80 )
			throw new OverflowException();
		writeByte(x & 0xFF);
		return this;
	}

	public function writeUInt8( x : Int ) : Output {
		return writeByte(x);
	}

	/**
		Write a signed 16 bit integer
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeInt16( x : Int ) : Output  {
		if( x < -0x8000 || x >= 0x8000 ) throw new OverflowException();
		writeUInt16(x & 0xFFFF);
		return this;
	}

	/**
		Write an unsigned 16 bit integer
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeUInt16( x : Int ) : Output  {
		if( x < 0 || x >= 0x10000 ) throw new OverflowException();
		if( bigEndian ) {
			writeByte(x >> 8);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte(x >> 8);
		}
		return this;
	}

	/**
		Write a signed 24 bit integer
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeInt24( x : Int ) : Output {
		if( x < -0x800000 || x >= 0x800000 ) throw new OverflowException();
		writeUInt24(x & 0xFFFFFF);
		return this;
	}

	/**
		Write an unsigned 24 bit integer
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeUInt24( x : Int ) : Output  {
		if( x < 0 || x >= 0x1000000 ) throw new OverflowException();
		if( bigEndian ) {
			writeByte(x >> 16);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x >> 16);
		}
		return this;
	}

	/**
		Write a signed 31 bit integer in 4 bytes
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeInt31( x : Int ) : Output  {
		#if !neko
		if( x < -0x40000000 || x >= 0x40000000 ) throw new OverflowException();
		#end
		if( bigEndian ) {
			writeByte(x >>> 24);
			writeByte((x >> 16) & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte((x >> 16) & 0xFF);
			writeByte(x >>> 24);
		}
		return this;
	}

	/**
		Write an unsigned 30 bit integer in 4 bytes
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeUInt30( x : Int ) : Output  {
		if( x < 0 #if !neko || x >= 0x40000000 #end ) throw new OverflowException();
		if( bigEndian ) {
			writeByte(x >>> 24);
			writeByte((x >> 16) & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte(x & 0xFF);
		} else {
			writeByte(x & 0xFF);
			writeByte((x >> 8) & 0xFF);
			writeByte((x >> 16) & 0xFF);
			writeByte(x >>> 24);
		}
		return this;
	}

	/**
		Write a signed 32 bit integer in 4 bytes
		@throws chx.lang.OverflowException if value has too many bits.
	**/
	public function writeInt32( x : haxe.Int32 ) : Output  {
		if( bigEndian ) {
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,24)) );
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,16)) & 0xFF );
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,8)) & 0xFF );
			writeByte( haxe.Int32.toInt(haxe.Int32.and(x,haxe.Int32.ofInt(0xFF))) );
		} else {
			writeByte( haxe.Int32.toInt(haxe.Int32.and(x,haxe.Int32.ofInt(0xFF))) );
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,8)) & 0xFF );
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,16)) & 0xFF );
			writeByte( haxe.Int32.toInt(haxe.Int32.ushr(x,24)) );
		}
		return this;
	}

	/**
		Inform that we are about to write at least a specified number of bytes.
		The underlying implementation can allocate proper working space depending
		on this information, or simply ignore it. This is not a mandatory call
		but a tip and is only used in some specific cases.
	**/
	public function prepare( nbytes : Int ) : Output  {
		return this;
	}

	/**
		Reads bytes directly from the specified Input until an
		EofException is encountered, writing untranslated
		bytes to this output.
		@param i An input stream
		@param bufsize A default buffer chunk size
		@throws chx.lang.BlockedException if the input blocks
	**/
	public function writeInput( i : Input, ?bufsize : Int ) : Output  {
		if( bufsize == null )
			bufsize = 4096;
		var buf = Bytes.alloc(bufsize);
		try {
			while( true ) {
				var len = i.readBytes(buf,0,bufsize);
				if( len == 0 )
					throw new BlockedException();
				var p = 0;
				while( len > 0 ) {
					var k = writeBytes(buf,p,len);
					if( k == 0 )
						throw new BlockedException();
					p += k;
					len -= k;
				}
			}
		} catch( e : EofException ) {
		}
		return this;
	}

	/**
		Write raw string data to the output. No length is added to the
		output stream.
		@param s String to write
		@see writeUTF()
	**/
	public function writeString( s : String ) : Output  {
		#if neko
		var b = untyped new Bytes(s.length,s.__s);
		#else
		var b = Bytes.ofString(s);
		#end
		writeFullBytes(b, 0, b.length);
		return this;
	}

	/**
		Writes a 16 bit unsigned int, then the string.
		@param s The string to be written to the stream
		@throws chx.lang.OverflowException if string length exceeds 65535 bytes
	**/
	public function writeUTF( s : String ) : Output {
		if(s.length > 0xFFFF)
			throw new chx.lang.OverflowException();
		writeUInt16(s.length);
		writeString(s);
		return this;
	}

	/**
	 * Writes a formatted string in the printf style.
	 * @see chx.text.Sprintf
	 * @param	format printf() compatible format
	 * @param	args arguments to substitute into format
	 * @param	prependLength set to true to use writeUTF() method
	 * @return this output stream
	 */
	public function printf( format : String, args:Array<Dynamic> = null, prependLength:Bool = false) : Output {
		var s = Sprintf.format(format, args);
		if (prependLength) {
			writeUTF(s);
		} else {
			writeString(s);
		}
		return this;
	}
	
	public function toString() : String  {
		return Type.getClassName(Type.getClass(this));
	}
	
#if (neko || cpp)
	static var _float_bytes = chx.Lib.load("std","float_bytes",2);
	static var _double_bytes = chx.Lib.load("std","double_bytes",2);
	#if neko
	static function __init__() untyped {
		Output.prototype.bigEndian = false;
	}
	#end
#end

}
