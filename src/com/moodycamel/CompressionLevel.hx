/*
   Copyright (c) 2011, Cameron Desrochers
   All rights reserved.

       Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.



Certain parts of this file are based on the zlib source.
As such, here is the zlib license in its entirety (from zlib.h):

  zlib.h -- interface of the 'zlib' general purpose compression library
  version 1.2.5, April 19th, 2010

  Copyright (C) 1995-2010 Jean-loup Gailly and Mark Adler

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  Jean-loup Gailly        Mark Adler
  jloup@gzip.org          madler@alumni.caltech.edu


  The data format used by the zlib library is described by RFCs (Request for
  Comments) 1950 to 1952 in the files http://www.ietf.org/rfc/rfc1950.txt
  (zlib format), rfc1951.txt (deflate format) and rfc1952.txt (gzip format).
*/



// This is a zlib/deflate implementation (from scratch!) that was
// created for use by PNGEncoder2, but should be fairly general
// purpose (the API is a bit ungainly though, mostly for
// performance reasons (e.g. no input buffering, assumes
// it's the one using flash.Memory (apart from the client), etc.).
// Tied rather inextricably to the Flash 10+ target (though most
// of the code would port easily to another language that provides
// fast access to raw chunks of memory, like C or C++).


// Some references:
// - RFC 1950 (zlib) and 1951 (DEFLATE)
// - The standard zlib implementation (available from http://zlib.net/)
// - "An Explanation of the Deflate Algorithm" (http://www.zlib.net/feldspar.html)
// - "Length-Limitted Huffman Codes" (http://cbloomrants.blogspot.com/2010/07/07-02-10-length-limitted-huffman-codes.html)
// - "Length-Limitted Huffman Codes Heuristic" (http://cbloomrants.blogspot.com/2010/07/07-03-10-length-limitted-huffman-codes.html)
// - A C implementation of an in-place Huffman code length generator (http://ww2.cs.mu.oz.au/~alistair/inplace.c)
// - FastLZ source: http://fastlz.googlecode.com/svn/trunk/fastlz.c
// - Reverse Parallel algorithm for reversing bits (http://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel)
// - Wikipedia article on canonical Huffman codes (http://en.wikipedia.org/wiki/Canonical_Huffman_code)
// - http://cstheory.stackexchange.com/questions/7420/relation-between-code-length-and-symbol-weight-in-a-huffman-code
// - MurmurHash3: http://code.google.com/p/smhasher/source/browse/trunk/MurmurHash3.cpp
// - Progressive Hashing: http://fastcompression.blogspot.com/2011/10/progressive-hash-series-new-method-to.html

package com.moodycamel;

//import flash.errors.Error;
//import flash.Lib;
//import flash.Memory;
//import flash.system.ApplicationDomain;
//import flash.utils.ByteArray;
//import flash.utils.Endian;

enum CompressionLevel {
    UNCOMPRESSED;       // Fastest
#if !(FAST_ONLY || NORMAL_ONLY || GOOD_ONLY)
    FAST;               // Huffman coding only
    NORMAL;             // Huffman + fast LZ77 compression
    GOOD;               // Huffman + good LZ77 compression

#elseif FAST_ONLY
    FAST;
#elseif NORMAL_ONLY
    NORMAL;
#elseif GOOD_ONLY
    GOOD;
#end
}
