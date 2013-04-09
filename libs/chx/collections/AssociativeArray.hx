/*
 * Copyright (c) 2011, The Caffeine-hx project contributors
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

package chx.collections;

/**
 * An associative array where keys can be set by strings or by interger values.
 * This structure can be iterated, where all the string keyed items being
 * iterated first, followed by the integer keyed items.
 **/
class AssociativeArray<T> {
	public var length(getLength, never) : Int;
	var _buf : Array<T>;
	var _hash : Hash<T>;

	public function new() {
		_buf = new Array();
		_hash = new Hash();
	}

	/**
	 * Pushes a value on to the end of the integer indexed portion
	 */
	public function push(v:T) : Void {
		_buf.push(v);
	}

	public function get(indexOrKey : Dynamic) : T {
		if(Std.is(indexOrKey, String))
			return _hash.get(cast indexOrKey);
		if(Std.is(indexOrKey, Int))
			return _buf[cast indexOrKey];
		return throw new chx.lang.FatalException("Must be string or interger type");
	}

	public function set(indexOrKey : Dynamic, v:T) : Void {
		if(Std.is(indexOrKey, String)) {
			_hash.set(cast indexOrKey, v);
			return;
		}
		if(Std.is(indexOrKey, Int)) {
			_buf[cast indexOrKey] = v;
			return;
		}
		return throw new chx.lang.FatalException("Must be string or interger type");
	}

	/**
	 * Will remove only at the key (int or string).
	 **/
	public function remove(indexOrKey : Dynamic) : Bool {
		if(Std.is(indexOrKey, String)) {
			return _hash.remove(cast indexOrKey);
		}
		if(Std.is(indexOrKey, Int)) {
			var i = Std.int(indexOrKey);
			if(i > _buf.length) return false;
			var front = _buf.slice(0, i);
			var back : Array<T> = new Array();
			if(i < _buf.length - 1)
				back = _buf.slice(i+1, _buf.length);
			_buf = front.concat(back);
			return true;
		}
		return throw new chx.lang.FatalException("Must be string or interger type");
	}

	/**
	 * The overall length, same as the property 'length'. Expensive operation
	 * since the string values need to be counted each time
	 **/
	public function getLength() : Int {
		var c = _buf.length;
		c += Lambda.count(_hash);
		return c;
	}

	/**
	 * Returns the length of the underlying integer based array only
	 * not including any keys set by strings
	 **/
	public function getIntegerArrayLength() : Int {
		return _buf.length;
	}

	public function iterator() : Iterator<T> {
		var inArray = false;
		var hi = _hash.iterator();
		var ai = _buf.iterator();
		return {
			hasNext :
				function() : Bool {
					if(!inArray) {
						if(hi.hasNext())
							return true;
						inArray = true;
					}
					return ai.hasNext();
				},
			next :
				function() : T {
					if(!inArray)
						return hi.next();
					return ai.next();
				}
		}
	}

	#if debug
	// haxe -neko test.n -main chx.collections.AssociativeArray -cp ../../ -D debug
	public static function main() {
		var a = new AssociativeArray<Null<Int>>();
		a.set(1,1);
		a.set(0,0);
		a.set("horse", 12);
		a.set("dog", 14);

		Assert.isEqual(0, a.get(0));
		Assert.isEqual(1, a.get(1));
		Assert.isEqual(12, a.get("horse"));
		Assert.isEqual(14, a.get("dog"));
		var msg : String = "";
		for(i in a)
			msg += i + " ";
		trace("The following line should have the values [12, 14, 0, 1]");
		trace(msg);

		a.set(2,2);
		a.set(3,3);
		a.set(4,4);
		Assert.isEqual(5, a.getIntegerArrayLength());
		Assert.isTrue(a.remove(3));
		Assert.isEqual(4, a.getIntegerArrayLength());
		msg = "";
		for(i in a)
			msg += i + " ";
		trace("The following line should have the values [12, 14, 0, 1, 2, 4]");
		trace(msg);

		Assert.isTrue(a.remove(3));
		Assert.isEqual(3, a.getIntegerArrayLength());
		msg = "";
		for(i in a)
			msg += i + " ";
		trace("The following line should have the values [12, 14, 0, 1, 2]");
		trace(msg);

		Assert.isTrue(a.remove("horse"));
		Assert.isEqual(3, a.getIntegerArrayLength());
		msg = "";
		for(i in a)
			msg += i + " ";
		trace("The following line should have the values [14, 0, 1, 2]");
		trace(msg);

		Assert.isFalse(a.remove("pony"));
		Assert.isFalse(a.remove(4));

		a.set("pony", null);
		Assert.isEqual(null, a.get("pony"));
		a.push(null);
		Assert.isEqual(null, a.get(a.getIntegerArrayLength()-1));
	}
	#end
}
