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
package chx.net.servers;

#if (neko || cpp)

import chx.net.TcpSocket;
import chx.net.servers.PacketServer;
import chx.net.servers.PacketServer.SocketInfo;
import chx.net.servers.PacketServer.ThreadMessage;

class TcpPacketServer<Client> extends PacketServer<Client> {

// 	public function new() {
// 		super();
// 		select_function = net.TcpSocket.select;
// 	}

	override function createSock() {
		return untyped new TcpSocket();
	}

	override function writeToClient(c : SocketInfo<Client>, buf : Bytes, pos:Int, len: Int) : Int {
		#if neko
			return socket_send(
				c.sock.__handle,
				buf.getData(),
				pos,
				len);
		#else
			return c.sock.output.writeBytes(buf, pos, len);
		#end
	}



#if neko
// 	private static var socket_send_char = chx.Lib.load("std","socket_send_char",2);
	private static var socket_send  = chx.Lib.load("std","socket_send",4);
#end
}

#end
