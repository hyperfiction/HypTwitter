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

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */
/**
 * UTCTime
 *
 * An ASN1 type for UTCTime, represented as a Date
 */
package chx.formats.der;


class UTCTime implements IAsn1Type
{
	public static inline var TYPE : Int = 0x17;
	public var date:Date;

	public function new(d:Date = null)
	{
		this.date = d;
	}

	public function getType():Int
	{
		return TYPE;
	}

	public function getDate() : Date {
		return date;
	}

	/**
	 * @param str YYMMDDHHmmss
	 **/
	public function setUTCTime(str:String):Void {
		var year:Int = Std.parseInt(str.substr(0, 2));
		if (year<50) {
			year+=2000;
		} else {
			year+=1900;
		}
		var month:Int = Std.parseInt(str.substr(2,2));
		var day:Int = Std.parseInt(str.substr(4,2));
		var hour:Int = Std.parseInt(str.substr(6,2));
		var minute:Int = Std.parseInt(str.substr(8,2));
		var second:Int = (str.length >= 12) ? Std.parseInt(str.substr(10,2)) : 0;
		// TODO: this could be off by up to a day compared to wall time.
		date = new Date(year, month-1, day, hour, minute, second);
	}


	public function toString():String {
		return date != null ? date.toString() : "unknown";
	}

	/**
	 * @todo implementation
	 **/
	public function toDER():Bytes {
		throw new chx.lang.UnsupportedException("not implemented");
		return null;
	}
}