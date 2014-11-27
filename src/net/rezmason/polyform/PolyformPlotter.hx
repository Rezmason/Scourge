package net.rezmason.polyform;

import net.rezmason.polyform.Step.*;
import net.rezmason.polyform.Ornament.*;

class PolyformPlotter {
    public inline static function render(poly:Polyform) {
        var minX = 0;
        var maxX = 0;
        var minY = 0;
        var maxY = 0;
        var points = [];
        var headings = [];
        poly.march(points, headings);
        for (point in points) {
            if (minX > point.x) minX = point.x;
            if (maxX < point.x) maxX = point.x;
            if (minY > point.y) minY = point.y;
            if (maxY < point.y) maxY = point.y;
        }
        var rows = maxY - minY;
        var cols = maxX - minX;
        var diagram = [for (row in 0...rows * 2 + 1) [for (col in 0...cols * 2 + 1) EMPTY]];
        var len = poly.length();
        var ike = len - 1;
        for (step in poly.eachStep()) {
            var x = (points[ike].x - minX) * 2;
            var y = (points[ike].y - minY) * 2;
            diagram[y][x] = (step == L) ? STEP_LEFT : (step == R) ? STEP_RIGHT : STEP_STRAIGHT;
            ike = (ike + 1) % len;
            switch (headings[ike]) {
                case 0: diagram[y + 0][x + 1] = EAST;
                case 1: diagram[y + 1][x + 0] = SOUTH;
                case 2: diagram[y + 0][x - 1] = WEST;
                case 3: diagram[y - 1][x + 0] = NORTH;
            }
        }
        for (row in 0...rows) {
            var inside = false;
            for (col in 0...cols) {
                if (diagram[row * 2 + 1][col * 2 + 0] == NORTH) inside = true;
                if (inside) diagram[row * 2 + 1][col * 2 + 1] = CELL;
                if (diagram[row * 2 + 1][col * 2 + 2] == SOUTH) inside = false;
            }
        }
        return diagram;
    }

    public inline static function compact(diagram:Array<Array<Ornament>>) {
        var rows = Std.int((diagram.length - 1) / 2);
        var cols = Std.int((diagram[0].length - 1) / 2);
        var compacted = [for (row in 0...rows) [for (col in 0...cols) diagram[row * 2 + 1][col * 2 + 1]]];
        // pad diagram
        for (row in compacted) {
            row.unshift(EMPTY);
            row.push(EMPTY);
        }
        compacted.unshift([for (col in 0...cols + 2) EMPTY]);
        compacted.push([for (col in 0...cols + 2) EMPTY]);
        // record coords of symbols in diagram
        for (row in 1...rows + 1) {
            for (col in 1...cols + 1) {
                if (compacted[row][col] == CELL) {
                    if (compacted[row - 1][col] != CELL) compacted[row - 1][col] = EDGE;
                    if (compacted[row + 1][col] != CELL) compacted[row + 1][col] = EDGE;
                    if (compacted[row][col - 1] != CELL) compacted[row][col - 1] = EDGE;
                    if (compacted[row][col + 1] != CELL) compacted[row][col + 1] = EDGE;
                    if (compacted[row - 1][col + 1] == EMPTY) compacted[row - 1][col + 1] = CORNER;
                    if (compacted[row + 1][col - 1] == EMPTY) compacted[row + 1][col - 1] = CORNER;
                    if (compacted[row - 1][col - 1] == EMPTY) compacted[row - 1][col - 1] = CORNER;
                    if (compacted[row + 1][col + 1] == EMPTY) compacted[row + 1][col + 1] = CORNER;
                }
            }
        }
        return compacted;
    }

    public inline static function toData(compactDiagram:Array<Array<Ornament>>) {
        var cells = [];
        var edges = [];
        var corners = [];
        for (row in 0...compactDiagram.length) {
            for (col in 0...compactDiagram[0].length) {
                switch (compactDiagram[row][col]) {
                    case CELL: cells.push([col, row]);
                    case EDGE: edges.push([col, row]);
                    case CORNER: corners.push([col, row]);
                    case _:
                }
            }
        }
        return [cells, edges, corners];
    }

    public inline static function print(diagram:Array<Array<Ornament>>) {
        return '\t' + [for (row in diagram) row.join(EMPTY)].join('\n\t');
    }
}
