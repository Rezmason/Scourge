package;

import Step.*;
using PolyformPlotter;

class PolyformGenerator {
    static function main() {
        var args = Sys.args();
        if (args.length > 0) generate(Std.parseInt(args[0]), args[1] == 'true', args[2]);
        else generate(5, false, null);
    }

    public static function generate(limit, generateFixed, outputPath) {
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
                for (poly in lastMatches) {
                    for (expansion in poly.expand(stringRules)) {
                        matchMap.remove(expansion.reflect());
                        matchMap[expansion] = expansion;
                    }
                }
                for (poly in matchMap) {
                    if (poly.winding() != 4) throw 'Invalid: $poly'; // This actually tests the rules, not the pieces.
                    if (!hasCoincidentPerimeter(poly)) matches.push(poly);
                }
            }
            matches.sort(Polyform.sortFunction);
            printPolyforms(ike, matches, generateFixed);
            polyominoes[ike] = generateData(matches, generateFixed);
            lastMatches = matches;
        }
        if (outputPath == null) Sys.println(polyominoes);
        else sys.io.File.saveContent(outputPath, haxe.Json.stringify(polyominoes));
    }

    inline static function generateData(matches:Array<Polyform>, generateFixed:Bool) {
        return [ for (poly in matches) 
            [ for (flip in 0...(generateFixed ? poly.numReflections() : 1)) 
                [ for (rot in 0...(generateFixed ? poly.numRotations() : 1)) 
                    (flip == 1 ? poly.reflect(false) : poly).rotate(rot).render().compact().toData()
                ]
            ]
        ];
    }

    inline static function printPolyforms(size:Int, polys:Array<Polyform>, generateFixed:Bool) {
        var freeCount = 0;
        var fixedCount = 0;
        for (poly in polys) {
            freeCount++;
            fixedCount += poly.numReflections() * poly.numRotations();
            Sys.println('$size $freeCount $poly(${poly.numReflections()},${poly.numRotations()})');
            if (generateFixed) {
                var numRot = poly.numRotations();
                for (flip in 0...poly.numReflections()) {
                    var flippedPoly = (flip == 1 ? poly.reflect(false) : poly);
                    for (rot in 0...numRot) {
                        var transformedPoly = flippedPoly.rotate(rot);
                        Sys.println('$flip,$rot\n${transformedPoly.render().compact().print()}');
                    }
                }
            } else {
                Sys.println(poly.render().print());
            }
        }
        Sys.println('There are $freeCount free polyominoes of size $size with no holes.');
        Sys.println('There are $fixedCount fixed polyominoes of size $size with no holes.');
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
}
