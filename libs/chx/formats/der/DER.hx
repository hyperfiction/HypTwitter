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
 * DER
 *
 * A basic class to parse DER structures.
 * Incomplete, but sufficient to extract whatever data we need so far.
 */
package chx.formats.der;
import math.BigInteger;
import chx.formats.der.Sequence;
import chx.formats.der.Types.AsnStruct;
import chx.io.BytesOutput;
import chx.io.BytesInput;

class DER {
	// goal 1: to be able to parse an RSA Private Key PEM file.
	// goal 2: to parse an X509v3 cert. kinda.

	/*
	 * DER for dummies:
	 * http://luca.ntop.org/Teaching/Appunti/asn1.html
	 *
	 * This class does the bare minimum to get by. if that.
	 */

	public static var indent:String = "";

	/**
	 * Parse DER encoded ByteString into component Asn1 types. Optional structures
	 * are defined in Types.hx
	 * @param der Bytes object containing der encoded object
	 **/
	public static function read( der : Bytes, structure:Array<AsnStruct>=null ):IAsn1Type {
		var bi = new BytesInput(der);
		bi.bigEndian = true;
		//#if CAFFEINE_DEBUG
		//trace("DER.read: der.length: " + der.length + " position: " + bi.position);
		//#end
		return parse(bi, structure);
	}

	/**
	 * Parse DER encoded ByteString into component Asn1 types. Optional structures
	 * are defined in Types.hx
	 * @todo Neko may fail on determining packet length due to integer overflow. Extremely unlikely considering what comes DER packaged ;)
	 **/
	private static function parse(der:BytesInput, structure:Array<AsnStruct>=null):IAsn1Type
	{
		#if CAFFEINE_DEBUG
		//trace("DER.parse " + der.position);
		if (der.position == 0) {
			trace("DER.parse: "+der.getBytesCopy().toHex());
			trace("DERlength: "+der.getBytesCopy().length);
		}
		#end
		var type:Int = der.readUInt8();
		var otype  = type;
		var constructed:Bool = (type&0x20)!=0;
		type &=0x1F;
		// length
		var len:Int = der.readUInt8();
		var ocount:Int = 1;
		if (len>=0x80) { // long form of length
			// TODO: may fail in neko.
			var count:Int = len & 0x7f;
			ocount = 1 + count;
			len = 0;
			while (count>0) {
				len = (len<<8) | der.readUInt8();
				count--;
				#if CAFFEINE_DEBUG
				trace(indent + "len: 0x" + StringTools.hex(len));
				#end
			}
		}
		#if CAFFEINE_DEBUG
		var ts = indent + "TYPE: 0x"+StringTools.hex(otype,2)+"/0x" + StringTools.hex(type,2) + " Len: "+len;
		if(constructed) ts += " constructed ";
		ts += ". Used " + ocount + " bytes for length. Current position: " + der.position;
		trace(ts);
		#end
		// data
		var b:Bytes = null;
		switch (type) {
		//case 0x00: // WHAT IS THIS THINGY? (seen as 0xa0)
			// (note to self: read a spec someday.)
			// for now, treat as a sequence.
		case 0x00,0x10: // SEQUENCE/SEQUENCE OF. whatever
			#if CAFFEINE_DEBUG
			trace(indent + "SEQUENCE");
			var oindent = indent;
			indent += "    ";
			#end
			// treat as an array
			var p:Int = der.position;
			var o:Sequence = new Sequence(type);
			var arrayStruct:Array<AsnStruct> = null;

			// copy the array, as we destroy it later.
			if (structure != null)// && Std.is(structure, Array))
				arrayStruct = /*cast*/ structure.concat([]);

			while (der.position < p+len) {
				#if CAFFEINE_DEBUG
				trace(indent + "SEQUENCE LOOP pos: " + der.position + "/" + Std.string(p+len));
				#end
				var tmpStruct:AsnStruct = null;
				if (arrayStruct != null)
					tmpStruct = arrayStruct.shift();

				while (tmpStruct != null && tmpStruct.optional)
				{
					// make sure we have something that looks reasonable.
					// XXX I'm winging it here..
					var wantConstructed:Bool = Std.is(tmpStruct.value, Array);
					var isConstructed:Bool = isConstructedType(der);
					#if CAFFEINE_DEBUG
					trace(indent + "Checking " + tmpStruct.name + " " + ((wantConstructed == isConstructed)?"matched":"not equal"));
					#end
					if (wantConstructed != isConstructed) {
						// not found. put default stuff, or null
						o.push(tmpStruct.defaultValue);
						o.set(tmpStruct.name, tmpStruct.defaultValue);
						// try the next thing
						tmpStruct = arrayStruct.shift();
					}
					else {
						break;
					}
				}
				if (tmpStruct != null) {
					var name:String = tmpStruct.name;
					var value:Dynamic = tmpStruct.value;
					#if CAFFEINE_DEBUG
					trace(indent + "Found object '" + name + "'. " + (tmpStruct.extract?"Must extract":"No data to extract"));
					#end
					// do we need to keep a binary copy of this element
					if (tmpStruct.extract) {
						var op:Int = der.position;
						var size:Int = getLengthOfNextElement(der);
						var buf:Bytes = Bytes.alloc(size);
						der.readBytes(buf, 0, size);
						o.set(name+"_bin", new ExtractedBytes(buf));
						der.position = op;
					}
					var obj:IAsn1Type = DER.parse(der, value);
					o.push(obj);
					o.set(name, obj);
				}
				else {
					#if CAFFEINE_DEBUG
					trace(indent + "=== Parsing next element ==");
					#end
					o.push(DER.parse(der));
					#if CAFFEINE_DEBUG
					trace(indent + "===========================");
					#end
				}
			}
			#if CAFFEINE_DEBUG
			indent = oindent;
			trace(indent + "SEQUENCE END: at position " + der.position);
			#end
			return o;
		case 0x11: // SET/SET OF
			#if CAFFEINE_DEBUG
			trace(indent + "SET");
			var oindent = indent;
			indent += "    ";
			#end
			var p:Int = der.position;
			var s:Set = new Set();
			while (der.position < p+len) {
				s.push(DER.parse(der));
			}
			#if CAFFEINE_DEBUG
			indent = oindent;
			trace(indent + "SET END: at position " + der.position);
			#end
			return s;
		case 0x02: // INTEGER
			// put in a BigInteger
			b = Bytes.alloc(len);
			der.readBytes(b,0,len);
			var bi = new Integer(b);
			#if CAFFEINE_DEBUG
			trace(indent + "INTEGER: " + bi.toHex());
			#end
			return bi;
		case 0x06: // OBJECT IDENTIFIER:
			b = Bytes.alloc(len);
			der.readBytes(b,0,len);
			var oi = new ObjectIdentifier(b);
			#if CAFFEINE_DEBUG
			trace(indent + "OID: " + oi.toString());
			#end
			return oi;
		case 0x05: // NULL
			#if CAFFEINE_DEBUG
			trace(indent + "NULL TYPE:");
			#end
			if(len != 0) // if len!=0, something's horribly wrong.
				throw "unexpected length: type 0x05";
			return null;
		case 0x13: // PrintableString
			var ps:PrintableString = new PrintableString(der.readMultiByteString(len, "US-ASCII"));
			#if CAFFEINE_DEBUG
			trace(indent + "PRINTABLE STRING: " + ps.toString());
			#end
			return ps;
		//case 0x22: // XXX look up what this is. openssl uses this to store my email.
		case 0x22, 0x14: // T61String - an horrible format we don't even pretend to support correctly
			var ps : PrintableString = null;
			var nm = "T61String";
			if(type == 0x22) {
				nm = "OpenSSLString";
				ps = new OpenSSLString(der.readMultiByteString(len, "latin1"));
			}
			else
				ps = new T61String(der.readMultiByteString(len, "latin1"));
			#if CAFFEINE_DEBUG
			trace(indent + nm + ": " + ps.toString());
			#end
			return ps;
		case 0x16:
			var ps = new IA5String(der.readMultiByteString(len, "latin1"));
			#if CAFFEINE_DEBUG
			trace(indent + "IA5STRING: " + ps.toString());
			#end
			return ps;
		case 0x17: // UTCTime
			var ut:UTCTime = new UTCTime();
			ut.setUTCTime(der.readMultiByteString(len, "US-ASCII"));
			#if CAFFEINE_DEBUG
			trace(indent + "UTCTIME: " + ut.toString());
			#end
			return ut;
		default: // 0x03, 0x04: // BIT STRING, OCTET STRING
			if(type != 0x03 && type != 0x04) {
				trace(indent + "Cannot process DER TYPE "+type + " at position " + der.position);
			}
			if (type != 0x04 && der.peek() == 0) {
				//trace("Horrible Bit String pre-padding removal hack.");
				// I wish I had the patience to find a spec for this.
				// byte is # of bits of padding
				der.position++;
				len--;
			}
			// stuff in a OctetString for now.
			var bytes = Bytes.alloc(len);
			der.readBytes(bytes,0,len);
			var bs:OctetString = new OctetString(bytes);
			#if CAFFEINE_DEBUG
			trace(indent + bs.toHex(":"));
			#end
			return bs;
		}
	}

	private static function getLengthOfNextElement(b:BytesInput):Int {
		var p:Int = b.position;
		// length
		b.position++;
		var len:Int = b.readUInt8();
		if (len>=0x80) {
			// long form of length
			// TODO: neko may fail
			var count:Int = len & 0x7f;
			len = 0;
			while (count>0) {
				len = (len<<8) | b.readUInt8();
				count--;
			}
		}
		len += b.position-p; // length of length
		b.position = p;
		return len;
	}

	private static function isConstructedType(b:BytesInput):Bool {
		var type:Int = b.peek();
		return (type&0x20) != 0;
	}

	/**
		Create a DER buffer from byte data.
	**/
	public static function wrapDER(type:Int, data:Bytes):Bytes {
		var d:BytesOutput = new BytesOutput();
		d.bigEndian = true;
		d.writeByte(type);
		var len:Int = data.length;
		if (len<128) {
			d.writeByte(len);
		} else if (len<256) {
			d.writeByte(1 | 0x80);
			d.writeByte(len);
		} else if (len<65536) {
			d.writeByte(2 | 0x80);
			d.writeByte(len>>8);
			d.writeByte(len);
		} else if (len<65536*256) {
			d.writeByte(3 | 0x80);
			d.writeByte(len>>16);
			d.writeByte(len>>8);
			d.writeByte(len);
		} else {
			d.writeByte(4 | 0x80);
			d.writeByte(len>>24);
			d.writeByte(len>>16);
			d.writeByte(len>>8);
			d.writeByte(len);
		}
		d.writeBytes(data,0,data.length);
		return d.getBytes();
	}
}
