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

package chx.formats.der;

import chx.collections.AssociativeArray;

/**
 * Sequence
 *
 * An ASN1 type for a Sequence, implemented as an Array
 */
class Sequence extends AssociativeArray<IAsn1Type>, implements IAsn1Type
{
	public static inline var TYPE : Int = 0x10;
	var type:Int;

	public function new(iType:Int=0x10) {
		super();
		type = iType;
	}

	public function getType():Int
	{
		return type;
	}

	private function getTypeName() : String {
		return "Sequence";
	}

	/**
	 * @todo Repair
	 **/
	public function toDER():Bytes {
		var tmp:BytesBuffer = new BytesBuffer();
		for ( i in 0 ... length) {
			var e:IAsn1Type = _buf[i];
			if (e == null) { // XXX Arguably, I could have a der.Null class instead
				tmp.addByte(0x05);
				tmp.addByte(0x00);
			} else {
				tmp.add(e.toDER());
			}
		}
		return DER.wrapDER(type, tmp.getBytes());
	}

	public function toString():String {
		var s:String = DER.indent;
		var t:String = getTypeName()+"["+length+"][";
		DER.indent += "    ";
		///var first = true;
		for(i in 0..._buf.length) {
			//if(first) first = false; else t += "\n";
			//if (_buf[i]==null) continue;
			t += "\n" + DER.indent;
			var found:Bool = false;
			for(key in _hash.keys()) {
				if ( (Std.string(i) != key) && _buf[i] == _hash.get(key)) {
					if(Std.is(_buf[i], Sequence) || Std.is(_buf[i], Set)) {
						t+= key + ":\n" + DER.indent + Std.string(_buf[i]);
					} else {
						t += key + ": "+ Std.string(_buf[i]);
					}
					found = true;
					break;
				}
			}
			if (!found) {
				if(Std.is(_buf[i], Sequence) || Std.is(_buf[i], Set)) {
					t+= /*"\n" + DER.indent +*/ Std.string(_buf[i]);
				} else {
					t += Std.string(_buf[i]);
				}
			}
		}
		DER.indent= s;
		return t+"\n"+DER.indent+"]";
	}

	public function findAttributeValue(oid:String):IAsn1Type {
		for(set in this) {
			if ( Std.is(set, Set) ) {
				var child:IAsn1Type = cast(set, Set).get(0);
				if ( Std.is(child, Sequence)) {
					var sc:Sequence = cast child;
					var tmp:IAsn1Type = sc.get(0);
					if ( Std.is(tmp, ObjectIdentifier)) {
						var id:ObjectIdentifier = cast tmp;
						if (id.toString()==oid) {
							return sc.get(1);
						}
					}
				}
			}
		}
		return null;
	}

	public function findAttributeValues(oid:String):Array<IAsn1Type> {
		var rv : Array<IAsn1Type> = new Array();
		for(set in this) {
			if ( Std.is(set, Set) ) {
				var child:IAsn1Type = cast(set, Set).get(0);
				if ( Std.is(child, Sequence)) {
					var sc:Sequence = cast child;
					var tmp:IAsn1Type = sc.get(0);
					if ( Std.is(tmp, ObjectIdentifier)) {
						var id:ObjectIdentifier = cast tmp;
						if (id.toString()==oid) {
							rv.push(sc.get(1));
						}
					}
				}
			}
		}
		return rv;
	}
}
