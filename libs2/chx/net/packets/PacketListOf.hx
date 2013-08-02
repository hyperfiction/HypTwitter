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

/**
	Abstract base class for lists of packets. Do not override
	toBytes/fromBytes.
**/
class PacketListOf<T:Packet> extends Packet {
	/** count of packets in list **/
	public var length(getLength, null) : Int;
	var packets : List<T>;

	public function new() {
		super();
		packets = new List();
	}

	public override function onConstructed() {
		packets = new List();
	}

	/**
		Add to end of list
	**/
	public function add(item : T) : Void {
		packets.add(item);
	}

	public function clear() :Void {
		packets.clear();
	}

	public function first() : T {
		return packets.first();
	}

	function getLength() : Int {
		return packets.length;
	}

	public function iterator() : Iterator<T> {
		return packets.iterator();
	}

	public function last() : T {
		return packets.last();
	}

	/**
		Removes first item
	**/
	public function pop() : T {
		return packets.pop();
	}

	/**
		Push item to beginning of list
	**/
	public function push(item : T) : Void {
		packets.push(item);
	}

	public function remove(item : T) : Bool {
		return packets.remove(item);
	}


	override function toBytes(buf : chx.io.Output) : Void {
		buf.writeUInt30(this.packets.length);
		for(p in this.packets) {
			var b = p.write();
			buf.writeBytes(b, 0, b.length);
		}
	}

	override function fromBytes(buf : chx.io.Input) : Void {
		var count = buf.readUInt30();

		var ipr = new chx.net.io.InputPacketReader(buf);

		while(count > 0) {
			var pkt = ipr.read();
			if(pkt == null)
				throw new chx.lang.OutsideBoundsException("Expected " + count + " more packets");
			packets.add(cast pkt);
			count--;
		}
	}

}
