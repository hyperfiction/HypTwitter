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

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */
/**
 * ObjectIdentifier
 *
 * An ASN1 type for an ObjectIdentifier
 */
package chx.formats.der;
import chx.io.BytesInput;

class ObjectIdentifier implements IAsn1Type
{
	public static inline var TYPE : Int = 0x06;
	private var oid:Array<Int>;

	/**
	 * Create a new OID from either a String or Bytes
	 **/
	public function new(b:Dynamic) {
		if (Std.is(b, Bytes)) {
			parse(cast b);
		} else if (Std.is(b, String)) {
			generate(cast b);
		} else {
			throw "Invalid call to new ObjectIdentifier";
		}
	}

	private function generate(s:String):Void {
		var p = s.split(".");
		oid = new Array();
		for(i in p) {
			oid.push(Std.parseInt(i));
		}
	}

	private function parse(b:Bytes):Void {
		// parse stuff
		// first byte = 40*value1 + value2
		var bi = new BytesInput(b);
		var o:Int = bi.readUInt8();
		var a:Array<Int> = [];
		a.push(Std.int(o/40));
		a.push(Std.int(o%40));
		var v:Int = 0;
		while (bi.bytesAvailable>0) {
			o = bi.readUInt8();
			var last:Bool = (o&0x80)==0;
			o &= 0x7f;
			v = v*128 + o;
			if (last) {
				a.push(v);
				v = 0;
			}
		}
		oid = a;
	}

	public function getType():Int
	{
		return TYPE;
	}

	public function toDER():Bytes {
		var tmp:Array<Int> = [];
		tmp[0] = oid[0]*40 + oid[1];
		for(i in 2 ... oid.length) {
			var v:Int = oid[i];
			if (v<128) {
				tmp.push(v);
			} else if (v<128*128) {
				tmp.push( (v>>7)|0x80 );
				tmp.push( v&0x7f );
			} else if (v<128*128*128) {
				tmp.push( (v>>14)|0x80 );
				tmp.push( (v>>7)&0x7f | 0x80 );
				tmp.push( v&0x7f);
			} else if (v<128*128*128*128) {
				tmp.push( (v>>21)|0x80 );
				tmp.push( (v>>14) & 0x7f | 0x80 );
				tmp.push( (v>>7) & 0x7f | 0x80 );
				tmp.push( v & 0x7f );
			} else {
				throw "OID element to large.";
			}
		}
		var length = tmp.length;
		tmp.unshift(length); // assume length is small enough to fit here.
		tmp.unshift(TYPE);
		var b:BytesBuffer = new BytesBuffer();
		var l = tmp.length;
		for(i in 0...l)
			b.addByte(tmp[i]);
		return b.getBytes();
	}

	public function toString():String {
		return oid.join(".");
	}

	public function dump():String {
		return "OID["+toString()+"]";
	}
}
