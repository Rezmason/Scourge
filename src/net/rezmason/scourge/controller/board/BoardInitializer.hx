package net.rezmason.scourge.controller.board;

import haxe.Utf8;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.ScourgeStrings.*;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.ScourgeColorPalette.*;
import net.rezmason.scourge.View;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.grid.GridUtils;

class BoardInitializer {

    var board:Body;
    var view:View;
    var ecce:Ecce;
    var qBoard:Query;

    public var animCompleteSignal(default, null):Zig<Void->Void> = new Zig();

    public function new():Void {
        ecce = new Present(Ecce);
        view = new Present(View);
        board = view.board;
        qBoard = ecce.query([BoardSpaceView, BoardSpaceState]);
    }

    public function run() {
        // First pass: tag and remove view from unnecessary walls, calculate approximate board radius
        var numSpacesThatMatter = 0;
        var trimmings:Map<Int, Bool> = new Map();
        var maxDistSquared:Float = 0;
        for (entity in qBoard) {
            var spaceState = entity.get(BoardSpaceState);
            var view = entity.get(BoardSpaceView);
            if (spaceState.petriData.isWall) {
                var hasEmptyNeighbor = false;
                for (neighbor in spaceState.cell.neighbors) {
                    if (neighbor != null && !neighbor.value.get(BoardSpaceState).petriData.isWall) {
                        hasEmptyNeighbor = true;
                        break;
                    }
                }
                if (hasEmptyNeighbor) {
                    numSpacesThatMatter++;
                } else {
                    trimmings[spaceState.cell.id] = true;
                    entity.remove(BoardSpaceView);
                }
            } else {
                numSpacesThatMatter++;
            }
            var pos = spaceState.petriData.pos;
            var distSquared = pos.x * pos.x + pos.y * pos.y + pos.z * pos.z;
            if (maxDistSquared < distSquared) maxDistSquared = distSquared;
        }

        // Scale board so that board fits within scene's bounds
        board.transform.identity();
        var boardScale = 0.9 / Math.sqrt(maxDistSquared * 2);
        board.transform.appendScale(boardScale, boardScale, boardScale);
        board.glyphScale = boardScale * 0.5;
        view.boardScale = boardScale;
        view.piece.glyphScale = board.glyphScale;
        view.piece.transform.copyFrom(board.transform);
        view.bite.glyphScale = board.glyphScale;
        view.bite.transform.copyFrom(board.transform);

        // Second pass: populate views with glyphs, draw the walls (which don't change)
        var itr = 0;
        board.growTo(numSpacesThatMatter * 3);
        var stretch = board.glyphTexture.font.glyphRatio;
        for (entity in qBoard) {
            var view = entity.get(BoardSpaceView);
            var spaceState = entity.get(BoardSpaceState);
            var pos = spaceState.petriData.pos;
            
            var bottom = view.bottom = board.getGlyphByID(itr + 0).reset().SET({pos:pos, paint_s:0});
            var top    = view.top =    board.getGlyphByID(itr + 1).reset().SET({pos:pos, paint_s:0, p:-0.01});
            var over   = view.over =   board.getGlyphByID(itr + 2).reset().SET({pos:pos, paint_s:1.5, paint_h:stretch, p:-0.03});

            if (spaceState.petriData.isWall) {
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in spaceState.cell.orthoNeighbors()) {
                    if (neighbor != null && !trimmings[neighbor.id] && neighbor.value.get(BoardSpaceState).petriData.isWall) {
                        bitfield = bitfield | (1 << numNeighbors);
                    }
                    numNeighbors++;
                }
                var char = Utf8.charCodeAt(BOX_SYMBOLS, bitfield);
                bottom.SET({char:char, color:BOARD_COLOR, h:stretch});
                top.SET({char:char, color:WALL_COLOR, h:stretch});
            } else {
                over.SET({s:0, paint:spaceState.cell.id});
            }

            view.lastTopTo = GlyphUtils.createGlyph().copyFrom(top);
            view.lastBottomTo = GlyphUtils.createGlyph().copyFrom(bottom);

            itr += 3;
        }
    }
}
