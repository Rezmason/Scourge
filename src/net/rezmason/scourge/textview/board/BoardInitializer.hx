package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.Strings.*;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.praxis.grid.GridUtils;

class BoardInitializer {

    var body:Body;
    var ecce:Ecce;
    var qBoard:Query;

    public var animCompleteSignal(default, null):Zig<Void->Void> = new Zig();

    public function new(ecce:Ecce, body:Body):Void {
        this.ecce = ecce;
        this.body = body;
        qBoard = ecce.query([BoardNodeView, BoardNodeState]);
    }

    public function run() {
        // First pass: tag and remove view from unnecessary walls, calculate approximate board radius
        var numSpacesThatMatter = 0;
        var trimmings:Map<Int, Bool> = new Map();
        var maxDistSquared:Float = 0;
        for (entity in qBoard) {
            var nodeState = entity.get(BoardNodeState);
            var view = entity.get(BoardNodeView);
            if (nodeState.petriData.isWall) {
                var hasEmptyNeighbor = false;
                for (neighbor in nodeState.locus.neighbors) {
                    if (neighbor != null && !neighbor.value.get(BoardNodeState).petriData.isWall) {
                        hasEmptyNeighbor = true;
                        break;
                    }
                }
                if (hasEmptyNeighbor) {
                    numSpacesThatMatter++;
                } else {
                    trimmings[nodeState.locus.id] = true;
                    entity.remove(BoardNodeView);
                }
            } else {
                numSpacesThatMatter++;
            }
            var pos = nodeState.petriData.pos;
            var distSquared = pos.x * pos.x + pos.y * pos.y + pos.z * pos.z;
            if (maxDistSquared < distSquared) maxDistSquared = distSquared;
        }

        // Scale body so that board fits within scene's bounds
        body.transform.identity();
        var scale = 0.8 / Math.sqrt(maxDistSquared * 2);
        body.transform.appendScale(scale, scale, scale);
        body.glyphScale = scale * 0.35;

        // Second pass: populate views with glyphs, draw the walls (which don't change)
        var itr = 0;
        body.growTo(numSpacesThatMatter * 3);
        for (entity in qBoard) {
            var view = entity.get(BoardNodeView);
            var nodeState = entity.get(BoardNodeState);
            var pos = nodeState.petriData.pos;
            
            var bottom = view.bottom = body.getGlyphByID(itr + 0).reset().SET({pos:pos});
            var top    = view.top =    body.getGlyphByID(itr + 1).reset().SET({pos:pos, p:-0.01});
            var over   = view.over =   body.getGlyphByID(itr + 2).reset().SET({pos:pos, p:-0.03});

            if (nodeState.petriData.isWall) {
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in nodeState.locus.orthoNeighbors()) {
                    if (neighbor != null && !trimmings[neighbor.id] && neighbor.value.get(BoardNodeState).petriData.isWall) {
                        bitfield = bitfield | (1 << numNeighbors);
                    }
                    numNeighbors++;
                }
                var char = Utf8.charCodeAt(BOX_SYMBOLS, bitfield);
                var stretch = body.glyphTexture.font.glyphRatio;
                bottom.SET({char:char, color:BOARD_COLOR, h:stretch});
                top.SET({char:char, color:WALL_COLOR, h:stretch});
            } else {
                bottom.SET({char:BOARD_CODE, color:BOARD_COLOR});
                top.SET({char:-1, color:BLACK});
            }
            itr += 3;
        }
    }
}
