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

#if flash9
/**
	Reads packets directly from a flash TcpSocket
**/
class FlashPacketReader {
	var sock : chx.net.TcpSocket;
	var type : Null<Int>;
	var length : Null<Int>;
	var xmlBo : chx.io.BytesOutput;
	var xmlBuf : Bytes;

	public function new(s : chx.net.TcpSocket) {
		this.sock = s;
		this.type = null;
		this.length = null;
	}

	/**
		Reads a packet from Bytes, returning a packet and number of bytes consumed.
		If there are not enough bytes in the buffer, the packet will be null with 0 bytes
		consumed.<br />
		<h1>Throws</h1>
		chx.lang.Exception - Packet type is not registered.
	**/
	public function read() : Packet {
		if(sock.__handle == null || sock.__handle.bytesAvailable == 0)
			return null;
		if(type == null) {
			type = sock.input.readByte();
			if(type == 0x3C)
				xmlBo = new chx.io.BytesOutput();
		}

		if(length == null)
			length = getPacketLength();
		if(length == null || sock.__handle.bytesAvailable < length - 5)
			return null;


		var p = Packet.createType(type);
		if(p == null)
			throw new chx.lang.Exception("Not a registered packet " + type);

		try {
			if(type == 0x3C) {
				untyped p.fromBytes(new chx.io.BytesInput(xmlBuf));
			}
			else {
				untyped p.fromBytes(sock.input);
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
		var hnd = sock.__handle;
		if(type == null)
			return null;
		if(type == 0)
			return 1;
		if(type == 0x3C) {
			var found = false;
			while( hnd.bytesAvailable > 0 ) {
				var b = sock.input.readByte();
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

		if(hnd.bytesAvailable < 4)
			return null;
		return sock.input.readInt31();
	}
}
#end