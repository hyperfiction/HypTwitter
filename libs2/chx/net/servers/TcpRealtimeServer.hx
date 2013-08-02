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
package system.net.servers;

import system.net.servers.RealtimeServer;
import system.net.servers.RealtimeServer.SocketInfos;
import system.net.servers.RealtimeServer.ThreadMessage;
import chx.net.Socket;

class TcpRealtimeServer<Client> extends RealtimeServer<chx.net.Socket,Client> {

	public function new() {
		super();
		select_function = chx.net.Socket.select;
	}

	override function createSock() {
		return new chx.net.Socket();
	}

	override function addClient( s : chx.net.Socket ) {
		var tid = Std.random(config.threadsCount);
		var thread = threads[tid];
		if( thread == null ) {
			thread = initThread();
			threads[tid] = thread;
		}
		var sh : { private var __handle : SocketHandle; } = s;
		var cinf : SocketInfos<chx.net.Socket, Client> = {
			sock : s,
			handle : sh.__handle,
			client : null,
			thread : thread,
			wbuffer : Bytes.alloc(config.writeBufferSize),
			wbytes : 0,
			rbuffer : Bytes.alloc(config.minReadBufferSize),
			rbytes : 0,
		};
		untyped s.output.writeChar = callback(writeClientChar,cinf);
		untyped s.output.writeBytes = callback(writeClientBytes,cinf);
		untyped s.output.writeByte = callback(writeClientChar,cinf);
		untyped s.output.writeString = callback(writeClientString,cinf);
		s.custom = cinf;
		cinf.thread.t.sendMessage(Connect(s));
	}


	override function clientWrite( c : SocketInfos<chx.net.Socket, Client> ) : Bool {
		var pos = 0;
		while( c.wbytes > 0 )
			try {
				var len = socket_send(c.handle, c.wbuffer.getData(), pos, c.wbytes);
				pos += len;
				c.wbytes -= len;
			} catch( e : Dynamic ) {
				if( e != "Blocking" )
					return false;
				break;
			}
		if( c.wbytes == 0 ) {
			c.thread.wsocks.remove(c.sock);
			clientFillBuffer(c.client);
		} else
			c.wbuffer.blit(0,c.wbuffer,pos,c.wbytes);
		return true;
	}

	public function run(uid : Null<Int>, gid : Null<Int>) {
		if(gid != null) {
			if(!system.Posix.setgid(haxe.Int32.ofInt(gid)))
				throw "Unable to switch to group id " + Std.string(gid);
		}
		if(uid != null) {
			if(!system.Posix.setuid(haxe.Int32.ofInt(uid)))
				throw "Unable to switch to user id " + Std.string(uid);
		}
		while( !shutdown ) {
			var s = sock.accept();
			s.setBlocking(false);
			addClient(s);
		}
		sock.close();
	}

#if neko
	private static var socket_send_char : SocketHandle -> Int -> Void = chx.Lib.load("std","socket_send_char",2);
	private static var socket_send : SocketHandle -> Void -> Int -> Int -> Int = chx.Lib.load("std","socket_send",4);
#end
}
