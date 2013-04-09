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

import chx.net.Socket;
import chx.net.packets.Packet;

private typedef ThreadInfo = {
	var t : chx.vm.Thread;
	var socks : Array<Socket>;
	var wsocks : Array<Socket>;
}

typedef SocketInfo<Client> = {
	var sock : Socket;
	var client : Client;
	var thread : ThreadInfo;
	var wbuffer : Bytes;
	var wbytes : Int;
	var rbuffer : Bytes;
	var rbytes : Int;
	var writeRaw : Bytes -> Void;
	var writePacket : Packet->Void;
}

enum ThreadMessage {
	Connect( s : Dynamic );
	Disconnect( s : Dynamic );
}

/**
	This is an abstract base server. To create a server, use classes like
	TcpPacketServer
**/
class PacketServer <Client> {

	public var config : {
		listenValue : Int,
		connectLag : Float,
		minReadBufferSize : Int,
		maxReadBufferSize : Int,
		minWriteBufferSize : Int,
		maxWriteBufferSize : Int,
		threadsCount : Int,
	};
	public var shutdown : Bool;
	public var eventLog : chx.log.IEventLog;

	var sock : Socket;
	var threads : Array<ThreadInfo>;
	var select_function : Dynamic;

	public function new() {
		threads = new Array();
		config = {
			listenValue : 10,
			connectLag : 0.05,
			minReadBufferSize : 1 << 10, // 1 KB
			maxReadBufferSize : 1 << 16, // 64 KB
			minWriteBufferSize : 1 << 10, // 1 KB
			maxWriteBufferSize : 1 << 18, // 256 KB
			threadsCount : 10,
		};
		shutdown = false;
		eventLog = new chx.log.EventLog("PacketServer", chx.log.LogLevel.ERROR);
	}

	public dynamic function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		var str = try Std.string(e) catch( e : Dynamic ) "unknown";
		eventLog.error(str + " : " + StringTools.trim(haxe.Stack.toString(stack)).split("\n").join(", "));
	}

	/**
		Binds to the specified host and port, then drops priveledges to the optional
		user and group ids
	**/
	public function bind( host : String, port : Int, uid : Null<Int>, gid : Null<Int> ) {
		sock = createSock();
		select_function = sock.selectFunction();
		sock.bind(host,port);
		sock.listen(config.listenValue);

		if(gid != null) {
			if(!chx.vm.Posix.setgid(haxe.Int32.ofInt(gid)))
				throw "Unable to switch to group id " + Std.string(gid);
		}
		if(uid != null) {
			if(!chx.vm.Posix.setuid(haxe.Int32.ofInt(uid)))
				throw "Unable to switch to user id " + Std.string(uid);
		}
	}

	public function run() {
		var tid : Int = 0;
		while( !shutdown ) {
			var s = sock.accept();
			s.setBlocking(false);
			var thread = threads[tid];
			if( thread == null ) {
				thread = initThread();
				threads[tid] = thread;
			}
			tid++;
			if(tid >= config.threadsCount)
				tid = 0;
			var cinf : SocketInfo<Client> = {
				sock : s,
				client : null,
				thread : thread,
				wbuffer : Bytes.alloc(config.minWriteBufferSize),
				wbytes : 0,
				rbuffer : Bytes.alloc(config.minReadBufferSize),
				rbytes : 0,
				writeRaw : null,
				writePacket : null
			};
			cinf.writePacket = callback(writePacket, cinf);
			cinf.writeRaw = callback(writeRaw, cinf);
			s.custom = cinf;
			cinf.thread.t.sendMessage(Connect(s));
		}
		sock.close();
	}

	/**
		Writing to client is done through SocketInfo.writePacket(Packet). This is the callback
		handler
	**/
	function writePacket( c : SocketInfo<Client>, pkt : Packet) {
		if(pkt == null)
			return;
		var buf = pkt.write();
		if(buf.length == 0)
			return;

		writeRaw(c, buf);
		/*
		var available = c.wbuffer.length - c.wbytes;
		while(available < buf.length) {
			var newsize = c.wbuffer.length * 2;
			if( newsize > config.maxWriteBufferSize ) {
				newsize = config.maxWriteBufferSize;
				if( c.wbuffer.length == config.maxWriteBufferSize )
					throw "Max output buffer size reached";
			}
			var newbuf = Bytes.alloc(newsize);
			newbuf.blit(0,c.wbuffer,0,c.wbytes);
			c.wbuffer = newbuf;
			available = newsize - c.wbytes;
		}

		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		c.wbuffer.blit(c.wbytes,buf,0,buf.length);
		c.wbytes += buf.length;
		*/
	}


	/**
		Writing to client is done through SocketInfo.writePacket(Packet). This is the callback
		handler
	**/
	function writeRaw( c : SocketInfo<Client>, buf : Bytes) {
		if(buf.length == 0)
			return;

		var available = c.wbuffer.length - c.wbytes;
		while(available < buf.length) {
			var newsize = c.wbuffer.length * 2;
			if( newsize > config.maxWriteBufferSize ) {
				newsize = config.maxWriteBufferSize;
				if( c.wbuffer.length == config.maxWriteBufferSize )
					throw "Max output buffer size reached";
			}
			var newbuf = Bytes.alloc(newsize);
			newbuf.blit(0,c.wbuffer,0,c.wbytes);
			c.wbuffer = newbuf;
			available = newsize - c.wbytes;
		}

		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		c.wbuffer.blit(c.wbytes,buf,0,buf.length);
		c.wbytes += buf.length;
	}

	function cleanup( t : ThreadInfo, s : Socket ) {
		var res = t.socks.remove(s);
		try s.close() catch( e : Dynamic ) { };
		t.wsocks.remove(s);
		if(!res)
			return;
		try {
			onClientDisconnected(s.custom.client);
		} catch( e : Dynamic ) {
			logError(e);
		}
	}

	/**
		Disconnect a client
	**/
	public function killClient( s : Socket ) {
		try s.shutdown(true,true) catch( e : Dynamic ) { };
		s.custom.thread.t.sendMessage(Disconnect(s));
	}


	///////////////////////////////////////////////////////////
	//            Thread Functions                           //
	///////////////////////////////////////////////////////////
	function initThread() {
		var t : ThreadInfo = {
			t : null,
			socks : new Array(),
			wsocks : new Array(),
		};
		t.t = chx.vm.Thread.create(callback(runThread,t));
		return t;
	}

	function runThread( t ) {
		while( true ) {
			try loopThread(t) catch( e : Dynamic ) logError(e);
		}
	}

	function loopThread( t : ThreadInfo ) {
		if( t.socks.length > 0 )
			readWriteThread(t);
		while( true ) {
			var m : ThreadMessage = chx.vm.Thread.readMessage(t.socks.length == 0);
			if( m == null ) break;
			switch( m ) {
			case Connect(s):
					t.socks.push(s);
					s.custom.client = onClientConnected(s);
					if( t.socks.length >= 64 ) {
						onServerFull(s.custom.client);
						logError("Max clients per thread reached");
						cleanup(t,s);
					}
			case Disconnect(s):
					cleanup(t,s);
			}
		}
	}

	function readWriteThread( t : ThreadInfo ) {
		var socks : { write : Array<Socket>, read : Array<Socket>, others : Array<Socket>};
		socks = select_function(t.socks,t.wsocks,null,config.connectLag);
		for( s in socks.read ) {
			var ok = try clientRead(s.custom)
				catch( e : Dynamic ) {
					logError(e); false;
				};
			if( !ok ) {
				socks.write.remove(s);
				cleanup(t,s);
			}
		}
		for( s in socks.write ) {
			var ok = try clientWrite(s.custom) catch( e : Dynamic ) { logError(e); false; };
			if( !ok )
				cleanup(t,s);
		}
	}

	function clientRead( c : SocketInfo<Client> ) {
		var available = c.rbuffer.length - c.rbytes;
		if( available == 0 ) {
			var newsize = c.rbuffer.length * 2;
			if( newsize > config.maxReadBufferSize ) {
				newsize = config.maxReadBufferSize;
				if( c.rbuffer.length == config.maxReadBufferSize )
					throw "Max buffer size reached";
			}
			var newbuf = Bytes.alloc(newsize);
			newbuf.blit(0,c.rbuffer,0,c.rbytes);
			c.rbuffer = newbuf;
			available = newsize - c.rbytes;
		}
		try {
			c.rbytes += c.sock.input.readBytes(c.rbuffer,c.rbytes,available);
		} catch( e : Dynamic ) {
			// if eof return false
			// if just Exception return false
			// rethrow (BlockedExceptions)
			if( Std.is(e, chx.lang.BlockedException))
				chx.Lib.rethrow(e);
			return false;
		}
		var pos = 0;
		while( c.rbytes > 0 ) {
			var pd = Packet.read(c.rbuffer, pos, c.rbytes);
			if(pd.packet == null)
				break;
			onPacket(c.client, pd.packet);
			pos += pd.bytes;
			c.rbytes -= pd.bytes;
		}
		if( pos > 0 )
			c.rbuffer.blit(0,c.rbuffer,pos,c.rbytes);
		return true;
	}

	function clientWrite( c : SocketInfo<Client> ) : Bool {
		var pos = 0;
		while( c.wbytes > 0 ) {
			try {
				var len = writeToClient(c, c.wbuffer, pos, c.wbytes);
				pos += len;
				c.wbytes -= len;
			} catch( e : Dynamic ) {
				if( e != "Blocking" )
					return false;
				break;
			}
		}
		if( c.wbytes == 0 ) {
			c.thread.wsocks.remove(c.sock);
		} else
			c.wbuffer.blit(0,c.wbuffer,pos,c.wbytes);
		return true;
	}



	///////////////////////////////////////////////////////////
	//            SocketType API Methods                     //
	///////////////////////////////////////////////////////////

	/**
		This must be overridden by a method that creates a new socket
	**/
	function createSock() : Socket {
		throw "createSock must be implemented";
		return null;
	}


	/**
		Override with method that sends data on client socket
	**/
	function writeToClient(c : SocketInfo<Client>, buf : Bytes, pos:Int, len: Int) : Int {
		return c.sock.output.writeBytes(buf, pos, len);
	}


	///////////////////////////////////////////////////////////
	//            Implentation API Methods                   //
	///////////////////////////////////////////////////////////

	/**
		Called when the max number of clients per thread is reached,
		before the client is disconnected.
	**/
	public function onServerFull( c : Client ) {
	}

	/**
		Must create and return an instance of Client for the given socket.
	**/
	public function onClientConnected( s : Socket ) : Client {
		return null;
	}

	/**
		Called when a complete packet is read from the client
	**/
	public function onPacket(c : Client, packet : Packet) {
		throw "onPacket must be implemented";
	}

	/**
		Called when a client is disconnected. Does not have to be overridden.
	**/
	public function onClientDisconnected( c : Client ) {
	}

}

#end
