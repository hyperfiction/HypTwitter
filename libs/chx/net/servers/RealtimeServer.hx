/*
 * Copyright (c) 2005, The haXe Project Contributors
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
package chx.net.servers;

import chx.net.Socket;

private typedef ThreadInfos<SockType> = {
	var t : chx.vm.Thread;
	var socks : Array<SockType>;
	var wsocks : Array<SockType>;
	var sleeps : Array<{ s : SockType, time : Float }>;
}

typedef SocketInfos<SockType,Client> = {
	var sock : SockType;
	var handle : SocketHandle;
	var client : Client;
	var thread : ThreadInfos<SockType>;
	var wbuffer : Bytes;
	var wbytes : Int;
	var rbuffer : Bytes;
	var rbytes : Int;
}

enum ThreadMessage {
	Connect( s : Dynamic );
	Disconnect( s : Dynamic );
	Wakeup( s : Dynamic, delay : Float );
}

/**
	This is an abstract base server. To create a server, use classes like
	TcpRealtimeServer
**/
class RealtimeServer<SockType : chx.net.Socket, Client> {

	public var config : {
		listenValue : Int,
		connectLag : Float,
		minReadBufferSize : Int,
		maxReadBufferSize : Int,
		writeBufferSize : Int,
		blockingBytes : Int,
		messageHeaderSize : Int,
		threadsCount : Int,
	};
	public var shutdown : Bool;
	var sock : SockType;
	var threads : Array<ThreadInfos<SockType>>;
	var select_function : Dynamic;

	public function new() {
		threads = new Array();
		config = {
			listenValue : 10,
			connectLag : 0.05,
			minReadBufferSize : 1 << 10, // 1 KB
			maxReadBufferSize : 1 << 16, // 64 KB
			writeBufferSize : 1 << 18, // 256 KB
			blockingBytes : 1 << 17, // 128 KB
			messageHeaderSize : 1,
			threadsCount : 10,
		};
		shutdown = false;
	}

	function createSock() : SockType {
		throw "createSock must be implemented";
		return null;
	}

	public function bind( host : chx.net.Host, port : Int ) {
		sock = createSock();
		sock.bind(host,port);
		sock.listen(config.listenValue);
	}

	public dynamic function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		var str = "["+Date.now().toString()+"] "+(try Std.string(e) catch( e : Dynamic ) "???");
		chx.Lib.print(str+"\n"+haxe.Stack.toString(stack));
	}

	function cleanup( t : ThreadInfos<SockType>, s : SockType ) {
		if( !t.socks.remove(s) )
			return;
		try s.close() catch( e : Dynamic ) { };
		t.wsocks.remove(s);
		var i = 0;
		while( i < t.sleeps.length )
			if( t.sleeps[i].s == s )
				t.sleeps.splice(i,1);
			else
				i++;
		try {
			clientDisconnected(getInfos(s).client);
		} catch( e : Dynamic ) {
			logError(e);
		}
	}

	function readWriteThread( t : ThreadInfos<SockType> ) {
		var socks : { write : Array<SockType>, read : Array<SockType>, others : Array<SockType>};
		socks = select_function(t.socks,t.wsocks,null,config.connectLag);
		for( s in socks.read ) {
			var ok = try clientRead(getInfos(s)) catch( e : Dynamic ) { logError(e); false; };
			if( !ok ) {
				socks.write.remove(s);
				cleanup(t,s);
			}
		}
		for( s in socks.write ) {
			var ok = try clientWrite(getInfos(s)) catch( e : Dynamic ) { logError(e); false; };
			if( !ok )
				cleanup(t,s);
		}
	}

	function loopThread( t : ThreadInfos<SockType> ) {
		var now = chx.Sys.time();
		var i = 0;
		while( i < t.sleeps.length ) {
			var s = t.sleeps[i];
			if( s.time <= now ) {
				t.sleeps.splice(i,1);
				clientWakeUp(getInfos(s.s).client);
			} else
				i++;
		}
		if( t.socks.length > 0 )
			readWriteThread(t);
		while( true ) {
			var m : ThreadMessage = chx.vm.Thread.readMessage(t.socks.length == 0);
			if( m == null ) break;
			switch( m ) {
			case Connect(s):
					t.socks.push(s);
					var inf = getInfos(s);
					inf.client = clientConnected(s);
					if( t.socks.length >= 64 ) {
						serverFull(inf.client);
						logError("Max clients per thread reached");
						cleanup(t,s);
					}
			case Disconnect(s):
					cleanup(t,s);
			case Wakeup(s,time):
					var sl = t.sleeps;
					var push = true;
					for( i in 0...sl.length )
						if( sl[i].time > time ) {
							sl.insert(i,{ s : s, time : time });
							push = false;
							break;
						}
					if( push )
						sl.push({ s : s, time : time });
			}
		}
	}

	function runThread( t ) {
		while( true ) {
			try loopThread(t) catch( e : Dynamic ) logError(e);
		}
	}

	function initThread() {
		var t : ThreadInfos<SockType> = {
			t : null,
			socks : new Array(),
			wsocks : new Array(),
			sleeps : new Array(),
		};
		t.t = chx.vm.Thread.create(callback(runThread,t));
		return t;
	}

	function writeClientChar( c : SocketInfos<SockType,Client>, ch : Int ) {
		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		c.wbuffer.set(c.wbytes,ch);
		c.wbytes += 1;
	}

	function writeClientBytes( c : SocketInfos<SockType,Client>, buf : Bytes, pos : Int, len : Int ) {
		if( len == 0 )
			return 0;
		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		c.wbuffer.blit(c.wbytes,buf,pos,len);
		c.wbytes += len;
		return len;
	}

	function writeClientString( c : SocketInfos<SockType,Client>, s : String) {
		writeClientBytes(c, Bytes.ofString(s), 0, s.length);
	}

	function addClient( s : SockType ) {
		throw "not implemented";
	}

	function getInfos( s : SockType ) : SocketInfos<SockType,Client> {
		return s.custom;
	}

	function clientWrite( c : SocketInfos<SockType,Client> ) : Bool {
		throw "not implemented";
		return false;
	}

	function clientRead( c : SocketInfos<SockType,Client> ) {
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
			if( !Std.is(e,chx.lang.EofException) && !Std.is(e,chx.io.IOException) )
				chx.Lib.rethrow(e);
			return false;
		}
		var pos = 0;
		while( c.rbytes >= config.messageHeaderSize ) {
			var m = readClientMessage(c.client,c.rbuffer,pos,c.rbytes);
			if( m == null )
				break;
			pos += m;
			c.rbytes -= m;
		}
		if( pos > 0 )
			c.rbuffer.blit(0,c.rbuffer,pos,c.rbytes);
		return true;
	}

	// ---------- API ----------------

	public function clientConnected( s : SockType ) : Client {
		return null;
	}

	public function readClientMessage( c : Client, buf : Bytes, pos : Int, len : Int ) : Int {
		return null;
	}

	public function clientDisconnected( c : Client ) {
	}

	/**
		Called whenever there are no bytes left
	**/
	public function clientFillBuffer( c : Client ) {
	}

	/**
		Override to receive a scheduled wakeUp() event
	**/
	public function clientWakeUp( c : Client ) {
	}

	/**
		Returns true if there are too many bytes already in the output buffer.
	**/
	public function isBlocking( s : SockType ) {
		return getInfos(s).wbytes > config.blockingBytes;
	}

	/**
		Schedules a client to receive a clientWakeUp event in delay seconds. This is
		a one-time event.
	**/
	public function wakeUp( s : SockType, delay : Float ) {
		var inf = getInfos(s);
		inf.thread.t.sendMessage(Wakeup(s,chx.Sys.time() + delay));
	}

	/**
		Disconnect a client
	**/
	public function stopClient( s : SockType ) {
		var inf = getInfos(s);
		try s.shutdown(true,true) catch( e : Dynamic ) { };
		inf.thread.t.sendMessage(Disconnect(s));
	}

	/**
		Called when the max number of clients per thread is reached,
		before the client is disconnected.
	**/
	public function serverFull( c : Client ) {
	}
}
