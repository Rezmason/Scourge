package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.Strings.*;
import net.rezmason.scourge.components.BoardNodeView;
import net.rezmason.scourge.game.build.PetriTypes;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.utils.CharCode;

class BoardSystem {

    var body:Body;
    var ecce:Ecce;
    var qBoardView:Query;

    public function new(ecce:Ecce, body:Body):Void {
        this.ecce = ecce;
        this.body = body;

        qBoardView = ecce.query([BoardNodeView]);
    }

    @:final public function init(_, _) {
        buildBoard();
    }

    public function buildBoard():Void {

        // First pass: find unnecessary walls, calculate approximate size
        var numSpacesThatMatter = 0;
        var trimmings:Map<Int, Bool> = new Map();
        var maxDistSquared:Float = 0;
        for (entity in qBoardView) {
            var locus = entity.get(BoardNodeView).locus;
            if (locus.value.isWall) {
                var hasEmptyNeighbor = false;
                for (neighbor in locus.neighbors) {
                    if (neighbor != null && !neighbor.value.isWall) {
                        hasEmptyNeighbor = true;
                        break;
                    }
                }

                if (hasEmptyNeighbor) numSpacesThatMatter++;
                else trimmings[locus.id] = true;
            } else {
                numSpacesThatMatter++;
            }
            var pos = locus.value.pos;
            var distSquared = pos.x * pos.x + pos.y * pos.y + pos.z * pos.z;
            if (maxDistSquared < distSquared) maxDistSquared = distSquared;
        }

        // Scale body so that board fits within scene's bounds
        body.transform.identity();
        var scale = 0.8 / Math.sqrt(maxDistSquared * 2);
        body.transform.appendScale(scale, scale, scale);
        body.glyphScale = scale * 0.35;

        body.growTo(numSpacesThatMatter * 3);

        var itr = 0;

        // Color the walls
        for (entity in qBoardView) {
            var view = entity.get(BoardNodeView);
            var locus = view.locus;

            if (trimmings[locus.id]) continue;
            
            var bottom = body.getGlyphByID(itr + 0);
            var top = body.getGlyphByID(itr + 1);
            var over = body.getGlyphByID(itr + 2);

            view.bottom = bottom;
            view.top = top;
            view.over = over;

            bottom.reset();
            top.reset();
            over.reset();

            top.set_pos(locus.value.pos);
            
            if (locus.value.isWall) {
                top.set_color(WALL_COLOR);
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in locus.orthoNeighbors()) {
                    if (neighbor != null && !trimmings[neighbor.id] && neighbor.value.isWall) {
                        bitfield = bitfield | (1 << numNeighbors);
                    }
                    numNeighbors++;
                }
                top.set_char(Utf8.charCodeAt(BOX_SYMBOLS, bitfield));
                top.set_h(body.glyphTexture.font.glyphRatio);
            }
            itr += 3;
        }
    }
}
