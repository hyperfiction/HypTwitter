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
	Ping packet
**/
class PacketPing extends Packet {
	/** Initially set to a random number, is the next ping id that will go out **/
	public static var pingIndex : Int;

	public var pingId : Int;
	public var timestamp : Float;

	public function new() {
		super();
		this.pingId = pingIndex;
		pingIndex++;
		this.timestamp = Date.now().getTime();
	}

	override function toBytes(buf:chx.io.Output) : Void {
		buf.writeInt31(this.pingId);
		buf.writeDouble(this.timestamp);
	}

	override function fromBytes(buf : chx.io.Input) : Void {
		this.pingId = buf.readInt31();
		this.timestamp = buf.readDouble();
	}

	inline static var VALUE : Int = 0x3A;

	static function __init__() {
		Packet.register(VALUE, PacketPing);
		pingIndex = Std.int(Math.random() * 10000.0);
	}

	override public function getValue() : Int {
		return VALUE;
	}
}
