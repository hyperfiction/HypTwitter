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

import chx.net.packets.Packet;
import chx.io.Input;
import chx.io.BufferedInput;
import chx.io.BytesOutput;
import chx.io.BytesInput;

/**
	Reads chx.net.packets directly from an Input. If the supplied chx.io.Input is
	not buffered, it will be buffered by the constructor.
**/
class InputPacketReader {
	var input : BufferedInput;
	var type : Null<Int>;
	var length : Null<Int>;
	var xmlBo : BytesOutput;
	var xmlBuf : Bytes;

	public function new(inp : Input) {
		if(Std.is(inp, BufferedInput))
			this.input = cast inp;
		else
			this.input = new BufferedInput(inp);
		input.bigEndian = true;
		this.type = null;
		this.length = null;
	}

	/**
		Reads a packet from Bytes, returning a packet and number of bytes consumed.
		If there are not enough bytes in the buffer, the packet will be null with 0 bytes
		consumed. Will throw a chx.lang.Exception if the packet type is not registered.
	**/
	public function read() : Packet {
		if(input.bytesAvailable == 0)
			return null;
		if(type == null) {
			type = input.readByte();
			if(type == 0x3C)
				xmlBo = new BytesOutput();
		}

		if(length == null)
			length = getPacketLength();
		if(length == null || input.bytesAvailable < length - 5)
			return null;


		var p = Packet.createType(type);
		if(p == null)
			throw new chx.lang.Exception("Not a registered packet " + type);

		try {
			if(type == 0x3C) {
				untyped p.fromBytes(new BytesInput(xmlBuf));
			}
			else {
				untyped p.fromBytes(input);
			}
		} catch(e : Dynamic) {
		}
		type = null;
		length = null;
		xmlBo = null;
		xmlBuf = null;
		return p;
	}

	/**
		Returns the length of the next packet in the supplied buffer, or null if it can not yet be determined
	**/
	function getPacketLength() : Null<Int> {
		if(type == null)
			return null;
		if(type == 0)
			return 1;
		if(type == 0x3C) {
			var found = false;
			while( input.bytesAvailable > 0 ) {
				var b = input.readByte();
				xmlBo.writeByte(b);
				if(b == 0) {
					found = true;
					break;
				}
			}
			if( !found )
				return null;
			xmlBuf = xmlBo.getBytes();
			xmlBo = null;
			return xmlBuf.length;
		}

		if(input.bytesAvailable < 4)
			return null;
		return input.readInt31();
	}
}
