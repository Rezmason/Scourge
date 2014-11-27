package net.rezmason.polyform;

import net.rezmason.polyform.Step.*;
using net.rezmason.polyform.PolyformPlotter;

class PolyformGenerator {
    #if !(js || flash)
    static function main() {
        var args = Sys.args();
        if (args.length > 0) {
            println(generate(Std.parseInt(args[0]), args[1] == 'true', true));
        }
        else println(generate(5, false, true));
    }
    #end

    public static function generate(limit:Int, generateFixed:Bool, ?verbose:Bool) {
        var rules = [
            [R, R] => [S, R, R, S],
            [S, R] => [L, R, R, S],
            [R, S] => [S, R, R, L],
            [S, S] => [L, R, R, L],
            [R, L, R] => [S, R, S],
        ];

        var stringRules = new Map();
        for (key in rules.keys()) stringRules[key.join('')] = rules[key].join('');
        var polyominoes = [];
        var lastMatches:Array<Polyform> = null;
        for (ike in 0...limit + 1) {
            var matches:Array<Polyform> = [];
            var matchMap:Map<String, Polyform> = new Map();
            if (ike == 0) {
                matches.push(Polyform.nihiloform());
            } else if (ike == 1) {
                matches.push(Polyform.monoform(4));
            } else {
                for (poly in lastMatches) for (expansion in poly.expand(stringRules)) matchMap[expansion] = expansion;
                for (poly in matchMap) {
                    if (poly.winding() != 4) throw 'Invalid: $poly'; // This actually tests the rules, not the pieces.
                    if (!hasCoincidentPerimeter(poly)) matches.push(poly);
                }
            }
            matches.sort(Polyform.sortFunction);
            if (verbose) printPolyforms(ike, matches, generateFixed);
            polyominoes.push([for (poly in matches) generateData(poly, generateFixed)]);
            lastMatches = matches;
        }
        return polyominoes;
    }

    inline static function generateData(poly:Polyform, generateFixed:Bool) {
        return 
        [ for (flip in 0...(generateFixed ? poly.numReflections() : 1)) 
            [ for (rot in 0...(generateFixed ? poly.numRotations() : 1)) 
                (flip == 1 ? poly.reflect() : poly).rotate(rot).render().compact().toData()
            ]
        ];
    }

    inline static function printPolyforms(size:Int, polys:Array<Polyform>, generateFixed:Bool) {
        var freeCount = 0;
        var fixedCount = 0;
        for (poly in polys) {
            freeCount++;
            fixedCount += poly.numReflections() * poly.numRotations();
            println('$size $freeCount $poly(${poly.numReflections()},${poly.numRotations()})');
            if (generateFixed) {
                var numRot = poly.numRotations();
                for (flip in 0...poly.numReflections()) {
                    var flippedPoly = (flip == 1 ? poly.reflect() : poly);
                    for (rot in 0...numRot) {
                        var transformedPoly = flippedPoly.rotate(rot);
                        println('$flip,$rot\n${transformedPoly.render().compact().print()}');
                    }
                }
            } else {
                println(poly.render().print());
            }
        }
        println('There are $freeCount free polyominoes of size $size with no holes.');
        println('There are $fixedCount fixed polyominoes of size $size with no holes.');
    }

    inline static function hasCoincidentPerimeter(poly:Polyform) {
        var found = false;
        if (poly.toString().substr(0, 3) == '$L$L$L') {
            found = true;
        } else {
            var points = [];
            poly.march(points, []);
            var pointsVisited = new Map();
            for (point in points) {
                if (pointsVisited['$point'] != null) {
                    found = true;
                    break;
                }
                pointsVisited['$point'] = true;
            }
        }
        return found;
    }

    inline static function println(str:Dynamic) { #if !(js || flash) Sys.println(str); #end }
}
