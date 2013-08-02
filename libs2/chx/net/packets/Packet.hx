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

package chx.net.packets;

import chx.io.BytesOutput;
import chx.io.BytesInput;
import chx.lang.FatalException;

/**
	A class to simplify writing network protocols. Extend with subclasses which each
	have a unique value (0 and 0x3A-0x3F are reserved) which call Packet.register in the
	static __init__. Then override toBytes and fromBytes with matching BytesOutput and
	BytesInput writing and reading of the class data.
**/
class Packet {
	static var pktRegister : IntHash<Class<Packet>>;

	/**
		Every class that extends Packet must register the packet identifying byte with it's class.
	**/
	public static function register(v : Int, c : Class<Packet>) {
		if(pktRegister == null) {
			pktRegister = new IntHash<Class<Packet>>();
		}
		if(v < 0 || v > 255)
			throw new chx.lang.OutsideBoundsException("Packet value out of range");

		if(v == 0x3A &&  Type.getClassName(c) != "chx.net.packets.PacketPing")
			throw new FatalException("Packet value 0x3C is reserved for chx.net.packets.PacketPing");
		if(v == 0x3B &&  Type.getClassName(c) != "chx.net.packets.PacketPong")
			throw new FatalException("Packet value 0x3C is reserved for chx.net.packets.PacketPong");
		if(v == 0x3C &&  Type.getClassName(c) != "chx.net.packets.PacketXmlData")
			throw new FatalException("Packet value 0x3C is reserved for chx.net.packets.PacketXmlData");
		if(v == 0x3D &&  Type.getClassName(c) != "chx.net.packets.PacketHaxeSerialized")
			throw new FatalException("Packet value 0x3D is reserved for chx.net.packets.PacketHaxeSerialized");
		if(v == 0 &&  Type.getClassName(c) != "chx.net.packets.PacketNull")
			throw new FatalException("Packet value 0x00 is reserved for chx.net.packets.PacketNull");
		if(pktRegister.exists(v))
			throw new FatalException("Packet value " + v + " already registered");
		for(i in pktRegister)
			if(Type.getClassName(i) == Type.getClassName(c))
				throw new FatalException("Packet of type " + Type.getClassName(c) + " already registered");
		pktRegister.set(v, c);
	}

	public var value(getValue, null) : Int;

	public function new() {
		this.value = getValue();
	}

	/**
		Called after a packet is created by createType() during packet reads.
		Incoming packets are created with Type.createEmptyInstance(), so any
		construction should be done here.
	**/
	public function onConstructed() {
		this.value = getValue();
	}

	/**
		Writes the packet to Bytes.
	**/
	public function write() : Bytes {
		var bb = newOutputBuffer();
		toBytes(bb);
		var data = bb.getBytes();

		var packet = newOutputBuffer();
		packet.writeByte(getValue());
		// Wraps data with a length
		packet.writeInt31(data.length + 5);
		packet.writeBytes(data, 0, data.length);

		return packet.getBytes();
	}

	/**
		Reads a packet from Bytes, returning a packet and number of bytes consumed.
		If there are not enough bytes in the buffer, the packet will be null with 0 bytes
		consumed.<br />
		<h1>Throws</h1><br />
		chx.lang.Exception - Packet type is not registered.
		chx.lang.OutsideBoundsException - Buffer not big enough
	**/
	public static function read(buf : Bytes, ?pos:Int, ?len:Int) : { packet: Packet, bytes: Int } {
		if(pos == null)
			pos = 0;
		if(len == null)
			len = buf.length - pos;
		if(pos + len > buf.length)
			throw new chx.lang.OutsideBoundsException();
		var msgLen = getPacketLength( buf, pos, len);
		if(msgLen == null || len < msgLen)
			return { packet: null, bytes : 0 }


		var p = createType(buf.get(pos));
		if(p == null)
			throw new chx.lang.Exception("Not a registered packet " + buf.get(pos));
		if(p.getValue() != 0x3C && p.getValue() != 0)
			pos += 5;
		var bi = newInputBuffer(buf, pos);
		p.fromBytes(bi);
		return { packet: p, bytes : msgLen};
	}

	/**
		Creates a new BytesOutput buffer with the correct endianness.
	**/
	static function newOutputBuffer() : BytesOutput {
		var b = new BytesOutput();
		b.bigEndian = true;
		return b;
	}

	/**
		Creates a new BytesInput with the correct endianness
	**/
	static function newInputBuffer(buf : Bytes, ?pos:Int, ?len : Int) : BytesInput {
		var i = new BytesInput(buf, pos, len);
		i.bigEndian = true;
		return i;
	}


	/**
		Returns the value of a packet
	**/
	public function getValue() : Int {
		throw new FatalException("override");
		return 0;
	}

	/**
		Packets mus override this to write all data to the data
	**/
	function toBytes(buf:chx.io.Output) : Void {
		throw new FatalException("override");
	}

	/**
		Read object in from specified Input, returning number of
		bytes consumed. The supplied Input must be in bigEndian format, by setting buf.bigEndian to true
	**/
	function fromBytes(buf:chx.io.Input) : Void {
		throw new FatalException("override");
	}

	public function toString() {
		var s = Type.getClassName(Type.getClass(this)) + ":";
		for(f in Reflect.fields(this)) {
			s += " " + f + "=" + Std.string(Reflect.field(this,f));
		}
		return s;
	}

	/**
		Creates a new packet fromt the byte value
	**/
	public static function createType(b:Int) : Packet {
		if(!pktRegister.exists(b))
			return null;
		var pkt = Type.createEmptyInstance(pktRegister.get(b));
		if(pkt != null)
			pkt.onConstructed();
		return pkt;
	}

	/**
		Returns the length of the next packet in the supplied buffer, or null if it can not yet be determined
	**/
	public static function getPacketLength( buf : Bytes, pos : Int, len : Int) : Null<Int> {
		if(buf.get(pos) == 0)
			return 1;
		if(pos + 2 > buf.length)
			return null;
		if(buf.get(pos) == 0x3C) {
			var p = pos;
			while( p < len ) {
				if( buf.get(p) == 0 )
					break;
				p++;
			}
			if( p == len )
				return null;
			return p - pos + 1;
		}
		if(pos + 5 > buf.length)
			return null;
		var bb = new BytesBuffer();
		bb.addByte(buf.get(pos+1));
		bb.addByte(buf.get(pos+2));
		bb.addByte(buf.get(pos+3));
		bb.addByte(buf.get(pos+4));
		var bi = newInputBuffer(bb.getBytes());
		return bi.readInt31();
	}

	/**
		Writes a string with leading string length to the buffer.
	**/
	public static function writeStringToBuf(s : String, buf : chx.io.Output) : Void {
		if(s == null || s.length == 0) {
			buf.writeUInt16(0);
		}
		else {
			if(s.length > 0xFFFF)
				throw new chx.lang.OutsideBoundsException("string length overflow");
			buf.writeUInt16(s.length);
			buf.writeString(s);
		}
	}

	/**
		Reads a length/string from buffer. Returns empty string for 0 length strings
	**/
	public static function readStringFromBuf(buf : chx.io.Input) : String {
		var len = buf.readUInt16();
		if(len > 0)
			return buf.readString(len);
		return "";
	}

	public static function writeBoolToBuf(v : Bool, buf : chx.io.Output) : Void {
		if(v)
			buf.writeByte(1);
		else
			buf.writeByte(0);
	}

	public static function readBoolFromBuf(buf : chx.io.Input) : Bool {
		var v = buf.readByte();
		if(v == 0)
			return false;
		return true;
	}

}
