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
 * Derived from javascript implementation Copyright (c) 2005 Tom Wu
 */

package math.reduction;

import math.BigInteger;

#if !neko
class Barrett implements math.reduction.ModularReduction {
	var m : BigInteger;
	var mu : BigInteger;
	var r2 : BigInteger;
	var q3 : BigInteger;
	// Barrett modular reduction
	public function new(m:BigInteger) {
		// setup Barrett
		r2 = BigInteger.nbi();
		q3 = BigInteger.nbi();
		BigInteger.ONE.dlShiftTo(2*m.t,r2);
		mu = r2.div(m);
		this.m = m;
	}

	public function convert(x:BigInteger) {
		if(x.sign < 0 || x.t > 2*m.t) return x.mod(m);
		else if(x.compare(m) < 0) return x;
		else { var r = BigInteger.nbi(); x.copyTo(r); reduce(r); return r; }
	}

	public function revert(x:BigInteger) { return x; }

	// x = x mod m (HAC 14.42)
	public function reduce(x:BigInteger) {
		x.drShiftTo(m.t-1,r2);
		if(x.t > m.t+1) { untyped x.t = m.t+1; x.clamp(); }
		mu.multiplyUpperTo(r2,m.t+1,q3);
		m.multiplyLowerTo(q3,m.t+1,r2);
		while(x.compare(r2) < 0) x.dAddOffset(1,m.t+1);
		x.subTo(r2,x);
		while(x.compare(m) >= 0) x.subTo(m,x);
	}

	// r = x^2 mod m; x != r
	public function sqrTo(x:BigInteger,r:BigInteger) {
		x.squareTo(r); reduce(r);
	}

	// r = x*y mod m; x,y != r
	public function mulTo(x:BigInteger,y:BigInteger,r:BigInteger) {
		x.multiplyTo(y,r); reduce(r);
	}
}
#end
