package net.rezmason.scourge.tools;

typedef IntCoord = {x:Int, y:Int};
typedef Piece = Array<IntCoord>;
typedef PieceGroup = Array<Array<Piece>>;
typedef Pattern = Array<Array<Bool>>;

typedef PatternFunction = Int->Void;

using Lambda;

class PieceGenerator {

    // Generates fixed polyominoes, and then sifts through them to find one-sided and free polyominoes
    // Used at compile time to generate the polyomino tables that go into the game.

    private static var fixedPatternsBySize:Array<Array<Pattern>> = [];
    private static var oneSidedPatternsBySize:Array<Array<Pattern>> = [];
    private static var freePatternsBySize:Array<Array<Pattern>> = [];

    private static var oneSidedGroupsBySize:Array<Array<Array<Pattern>>> = [];
    private static var freeGroupsBySize:Array<Array<Array<Array<Pattern>>>> = [];

    private static var patterns:Array<Array<Array<Pattern>>> = [fixedPatternsBySize, oneSidedPatternsBySize, freePatternsBySize];

    private static var fixedPiecesBySize:Array<Array<Piece>> = [];
    private static var oneSidedPiecesBySize:Array<Array<Piece>> = [];
    private static var freePiecesBySize:Array<Array<Piece>> = [];

    private static var pieces:Array<Array<Array<Piece>>> = [fixedPiecesBySize, oneSidedPiecesBySize, freePiecesBySize];
    private static var pieceGroups:Array<Array<PieceGroup>> = [];

    private static var patternFunctions:Array<PatternFunction> = [makeFixedPatterns, makeOneSidedPatterns, makeFreePatterns];

    // Returns pieces as arrays of coordinates. PieceGenerator's work is recursive,
    // so it's structured to repurpose its previous solutions.

    public static function generate(size:Int, type:Int):Array<Piece> {
        if (size < 0 || type < 0 || type > PieceType.FREE) throw "Invalid generator input";
        if (pieces[type][size] == null) makePieces(size, type);
        return pieces[type][size];
    }

    // Returns pieces arranged in a matrix, representing their rotations and reflections

    public static function generateGroups(size:Int):Array<PieceGroup> {
        if (size < 0) throw "Invalid generator input";
        if (pieceGroups[size] == null) makePieceGroups(size);
        return pieceGroups[size];
    }

    // Pieces are more compact and user-friendly representations of polyominoes than the internal Pattern objects

    private static function makePieces(size:Int, type:Int):Void {
        var patternSet:Array<Array<Pattern>> = patterns[type];
        if (patternSet[size] == null) patternFunctions[type](size);
        var pcs:Array<Piece> = [];
        for (pattern in patternSet[size]) pcs.push(patternToPiece(pattern));
        pieces[type][size] = pcs;
    }

    // Piece groups represent the relationships between pieces that are transformable into one another

    private static function makePieceGroups(size:Int):Void {
        if (freeGroupsBySize[size] == null) makeFixedPatterns(size);
        var pcGroups:Array<PieceGroup> = [];
        for (freeGroup in freeGroupsBySize[size]) pcGroups.push(groupToPieceGroup(freeGroup));
        pieceGroups[size] = pcGroups;
    }

    private static function makeFixedPatterns(size:Int):Void {
        //trace("FS " + size);

        var patterns:Array<Pattern> = [];

        if (size == 1) {
            // There's obviously only one polyomino of any sort that is of size one
            patterns.push([[true]]);
        } else {

            // Grab the previously found fixed patterns that are one size smaller
            if (fixedPatternsBySize[size - 1] == null) makeFixedPatterns(size - 1);

            // Generate new polyomino varieties from each earlier polyomino by appending a cell somewhere
            for (predecessor in fixedPatternsBySize[size - 1]) for (pattern in getProgeny(predecessor)) patterns.push(pattern);

            if (patterns.length > 1) {

                // Find the duplicates and null them
                for (ike in 0...patterns.length) {
                    if (patterns[ike] == null) continue;
                    for (jen in ike + 1...patterns.length) {
                        if (patterns[jen] != null && arePatternsEqual(patterns[ike], patterns[jen])) patterns[jen] = null;
                    }
                }
            }
        }

        // remove all null patterns
        while (patterns.remove(null)) {}

        fixedPatternsBySize[size] = patterns;
    }

    private static function makeOneSidedPatterns(size:Int):Void {
        //trace("OS " + size);

        // Grab the previously found fixed patterns
        if (fixedPatternsBySize[size] == null) makeFixedPatterns(size);
        var patterns:Array<Pattern> = fixedPatternsBySize[size].copy();
        var oneSidedGroups:Array<Array<Pattern>> = [];

        if (patterns.length > 1) {

            // Create rotations of the pattern, find the duplicates and null them
            for (ike in 0...patterns.length) {
                if (patterns[ike] == null) continue;

                var oneSidedGroup:Array<Pattern> = [patterns[ike]];

                var  r90Pattern:Pattern = rotatePattern(patterns[ike]);
                var r180Pattern:Pattern = rotatePattern(r90Pattern);
                var r270Pattern:Pattern = rotatePattern(r180Pattern);

                for (jen in ike + 1...patterns.length) {
                    var pattern2:Pattern = patterns[jen];
                    if (pattern2 != null) {
                        if (arePatternsEqual( r90Pattern, pattern2)) {
                            patterns[jen] = null;
                            oneSidedGroup[1] = pattern2;
                        } else if (arePatternsEqual(r180Pattern, pattern2)) {
                            patterns[jen] = null;
                            oneSidedGroup[2] = pattern2;
                        } else if (arePatternsEqual(r270Pattern, pattern2)) {
                            patterns[jen] = null;
                            oneSidedGroup[3] = pattern2;
                        }
                    }
                }

                oneSidedGroups.push(oneSidedGroup);
            }
        } else {
            oneSidedGroups.push([patterns[0]]);
        }

        // remove all null patterns
        while (patterns.remove(null)) {}

        oneSidedGroupsBySize[size] = oneSidedGroups;
        oneSidedPatternsBySize[size] = patterns;
    }

    private static function makeFreePatterns(size:Int):Void {
        //trace("FR " + size);

        // Grab the previously found one-sided patterns
        if (oneSidedPatternsBySize[size] == null) makeOneSidedPatterns(size);
        var patterns:Array<Pattern> = [];
        var oneSidedGroups:Array<Array<Pattern>> = oneSidedGroupsBySize[size].copy();
        var freeSidedGroups:Array<Array<Array<Pattern>>> = [];

        if (oneSidedGroups.length > 1) {

            // Create flipped rotations of the group's first pattern, find the duplicates and null them
            for (ike in 0...oneSidedGroups.length) {

                var oneSidedGroup:Array<Pattern> = oneSidedGroups[ike];

                if (oneSidedGroup == null) continue;

                var freeGroup:Array<Array<Pattern>> = [oneSidedGroup];

                patterns.push(oneSidedGroup[0]);

                var flipPattern:Pattern = vFlipPattern(oneSidedGroup[0]);
                var  r90Pattern:Pattern = rotatePattern(flipPattern);
                var r180Pattern:Pattern = rotatePattern(r90Pattern);
                var r270Pattern:Pattern = rotatePattern(r180Pattern);

                for (jen in ike + 1...oneSidedGroups.length) {
                    var group2:Array<Pattern> = oneSidedGroups[jen];
                    if (group2 != null) {
                        var pattern2:Pattern = group2[0];

                        if (pattern2 != null) {
                            var offset:Int = -1;

                            if (arePatternsEqual(flipPattern, pattern2)) {
                                offset = 0;
                            } else if (arePatternsEqual( r90Pattern, pattern2)) {
                                offset = 1;
                            } else if (arePatternsEqual(r180Pattern, pattern2)) {
                                offset = 2;
                            } else if (arePatternsEqual(r270Pattern, pattern2)) {
                                offset = 3;
                            }

                            if (offset != -1) {
                                while (offset-- > 0) group2.push(group2.shift());
                                freeGroup.push(group2);
                                oneSidedGroups[jen] = null;
                                break;
                            }
                        }
                    }
                }

                freeSidedGroups.push(freeGroup);
            }
        } else {
            freeSidedGroups.push([oneSidedGroups[0], oneSidedGroups[0]]);
            patterns.push(oneSidedGroups[0][0]);
        }

        freePatternsBySize[size] = patterns;
        freeGroupsBySize[size] = freeSidedGroups;
    }

    private static function rotatePattern(pattern:Pattern):Pattern {

        // I find it easier to flip the x and y coordinates of a pattern, and then flip the y axis

        var rotatedPattern:Pattern = [];
        for (row in 0...pattern.length) {
            rotatedPattern.push([]);
            for (col in 0...pattern.length) rotatedPattern[row][col] = pattern[col][row] == true;
            rotatedPattern[row].reverse();
        }

        cleanPattern(rotatedPattern);
        return rotatedPattern;
    }

    private static function vFlipPattern(pattern:Pattern):Pattern {

        // Reversing a pattern reflects it along the y axis

        pattern = copyPattern(pattern);
        pattern.reverse();
        cleanPattern(pattern);
        return pattern;
    }

    private static function copyPattern(pattern:Pattern):Pattern {
        // We're dealing with integers here, so it's not too hard to do a deep copy of a pattern
        var copy:Pattern = [];
        for (row in pattern) copy.push(row.copy());
        return copy;
    }

    private static function getProgeny(pattern:Pattern):Array<Pattern> {
        var progeny:Array<Pattern> = [];

        // We copy the pattern and then give it growing room.

        pattern = copyPattern(pattern); // !!
        for (row in pattern) row.unshift(false); // !!
        pattern.push([]); // !!
        pattern.unshift([]); // !!

        // For each empty cell adjacent to the filled cells in the pattern,

        for (y in 0...pattern.length) {
            for (x in 0...pattern.length) {
                if (pattern[y][x] != true) {

                    var valid:Bool = false;

                    if (pattern[y][x-1] || pattern[y][x+1]) {
                        valid = true;
                    } else if (pattern[y-1] != null && pattern[y-1][x]) {
                        valid = true;
                    } else if (pattern[y+1] != null && pattern[y+1][x]) {
                        valid = true;
                    }

                    if (valid) {

                        // We copy the pattern and fill the cell in that copy, and then clean the pattern

                        var child:Pattern = copyPattern(pattern);
                        child[y][x] = true;
                        cleanPattern(child); // !!
                        child.pop(); // !!
                        progeny.push(child);
                    }
                }
            }
        }

        return progeny;
    }

    private static function arePatternsEqual(pattern1:Pattern, pattern2:Pattern):Bool {
        // Because Array<Int> is really Array<Null<Int>>, we test whether all cells' equivalence to true are equal
        for (row in 0...pattern1.length) {
            var slice1:Array<Bool> = pattern1[row];
            var slice2:Array<Bool> = pattern2[row];
            for (col in 0...slice1.length) if ((slice1[col] == true) != (slice2[col] == true)) return false;
        }
        return true;
    }

    private static function cleanPattern(pattern:Pattern):Void {

        // Patterns are cropped before they are tested for equivalence

        var minX:Int = pattern.length;

        for (slice in pattern) {
            var col:Int = slice.indexOf(true);
            if (col != -1 && minX > col) minX = col;
        }

        if (minX < pattern.length) for (slice in pattern) slice.splice(0, minX);

        while (!pattern[0].has(true)) pattern.push(pattern.shift());
    }

    private static function patternToPiece(pattern:Pattern):Piece {
        var piece:Piece = [];
        for (y in 0...pattern.length) for (x in 0...pattern[y].length) if (pattern[y][x]) piece.push({x:x, y:y});
        return piece;
    }

    private static function groupToPieceGroup(group:Array<Array<Pattern>>):PieceGroup {
        var pieceGroup:PieceGroup = [];
        for (reflection in group) {
            var pieceReflection:Array<Piece> = [];
            pieceGroup.push(pieceReflection);
            for (pattern in reflection) {
                pieceReflection.push(patternToPiece(pattern));
            }
        }

        return pieceGroup;
    }

    private static function spitPattern(pattern:Pattern):String {

        // Handy.

        var str:String = "\n";
        var size:Int = pattern.length;
        for (row in pattern) {
            str += "";
            for (column in 0...size) {
                str += row[column] ? "•" : " ";
            }
            str += "\n";
        }
        return str;
    }
}

class PieceType {
    public inline static var FIXED:Int = 0;
    public inline static var ONE_SIDED:Int = 1;
    public inline static var FREE:Int = 2;
}
