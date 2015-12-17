/*
Copyright (C) 2006 Pedro Felzenszwalb

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
*/

/* distance transform */

package net.rezmason.math;


class FelzenszwalbSDF {

    public inline static var INF = 1E20;

    inline static function square(n:Float) return n * n;

    /* dt of 1d function using squared distance */
    inline static function computeDT(f:Array<Float>, n:UInt, d:Array<Float>, v:Array<Int>, z:Array<Float>) {
        var k:Int = 0;      // k: index of rightmost parabola in lower envelope
        v[0] = 0;           // v: locations of parabolas in lower envelope
        z[0] = -INF;        // z: locations of boundaries between parabolas
        z[1] =  INF;
        // compute the lower envelope
        for (q in 1...n) {
            var s:Float = ((f[q] + square(q)) - (f[v[k]] + square(v[k]))) / (2 * q - 2 * v[k]);
            while (s <= z[k]) {
                k--;
                s = ((f[q] + square(q)) - (f[v[k]] + square(v[k]))) / (2 * q - 2 * v[k]);
            }
            k++;
            v[k] = q;
            z[k] = s;
            z[k + 1] = INF;
        }
        k = 0;
        // fill in values of distance transform
        for (q in 0...n) {
            while (z[k + 1] < q) {
                k++;
            }
            d[q] = square(q - v[k]) + f[v[k]];
        }
    }

    /* dt of 2d function using squared distance */
    public static function computeDistanceField(width:UInt, height:UInt, input:Array<Float>):Array<Float> {
        var output = input.copy();
        for (i in 0...output.length) if (output[i] != 0) output[i] = INF;
        
        var f:Array<Float> = [];
        var d:Array<Float> = [];
        var v:Array<Int> = [];
        var z:Array<Float> = [];

        // transform along columns
        for (x in 0...width) {
            for (y in 0...height) f[y] = output[y * width + x];
            computeDT(f, height, d, v, z);
            for (y in 0...height) output[y * width + x] = d[y];
        }

        // transform along rows
        for (y in 0...height) {
            for (x in 0...width) f[x] = output[y * width + x];
            computeDT(f, height, d, v, z);
            for (x in 0...width) output[y * width + x] = d[x];
        }

        for (i in 0...width * height) output[i] = Math.sqrt(output[i]);
        return output;
    }

    /* signed dt of 2d function using squared distance */
    public static function computeSignedDistanceField(width:UInt, height:UInt, input:Array<Float>):Array<Float> {
        var distanceInput:Array<Float> = [];
        for (x in 0...width) {
            for (y in 0...height) {
                var isEdge = false;
                if (input[y * width + x] != 0) {
                    isEdge = isEdge || input[width * (y - 1) + x      ] == 0;
                    isEdge = isEdge || input[width * (y + 1) + x      ] == 0;
                    isEdge = isEdge || input[width * y       + (x - 1)] == 0;
                    isEdge = isEdge || input[width * y       + (x + 1)] == 0;
                }
                distanceInput[y * width + x] = isEdge ? 0 : 1;
            }
        }
        var output = computeDistanceField(width, height, distanceInput);
        for (i in 0...output.length) if (input[i] != 0) output[i] *= -1;
        return output;
    }
}
