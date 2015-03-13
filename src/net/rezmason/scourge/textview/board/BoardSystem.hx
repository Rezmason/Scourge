package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import net.rezmason.ecce.Ecce;
import net.rezmason.scourge.Strings.*;
import net.rezmason.scourge.game.build.PetriTypes;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.praxis.grid.GridUtils;
using net.rezmason.utils.CharCode;

class BoardSystem {

    var body:Body;
    var ecce:Ecce;

    public function new(body:Body, ecce:Ecce):Void {
        this.body = body;
        this.ecce = ecce;
    }

    public function buildBoard(loci:Array<PetriLocus>):Void {
        body.growTo(loci.length);

        // First pass: find unnecessary walls, calculate approximate size
        var trimmings = [];
        var maxDistSquared:Float = 0;
        for (locus in loci) {
            if (locus.value.isWall) {
                var hasEmptyNeighbor = false;
                for (neighbor in locus.neighbors) {
                    if (neighbor != null && !neighbor.value.isWall) {
                        hasEmptyNeighbor = true;
                        break;
                    }
                }
                if (!hasEmptyNeighbor) trimmings[locus.id] = locus;
            }
            var glyph = body.getGlyphByID(locus.id);
            var pos = locus.value.pos;
            glyph.reset();
            glyph.set_xyz(pos.x, pos.y, pos.z);
            var distSquared = pos.x * pos.x + pos.y * pos.y + pos.z * pos.z;
            if (maxDistSquared < distSquared) maxDistSquared = distSquared;
        }

        // Scale body so that board fits within scene's bounds
        body.transform.identity();
        var scale = 0.8 / Math.sqrt(maxDistSquared * 2);
        body.transform.appendScale(scale, scale, scale);
        body.glyphScale = scale * 0.4;

        // Color the walls
        for (locus in loci) {
            var glyph = body.getGlyphByID(locus.id);
            if (locus.value.isWall) {
                if (trimmings[locus.id] == locus) continue;
                glyph.set_color(WALL_COLOR);
                var itr:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in locus.orthoNeighbors()) {
                    if (neighbor != null && trimmings[neighbor.id] != neighbor && neighbor.value.isWall) {
                        bitfield = bitfield | (1 << itr);
                    }
                    itr++;
                }
                glyph.set_char(Utf8.charCodeAt(BOX_SYMBOLS, bitfield));
                glyph.set_h(body.glyphTexture.font.glyphRatio);
            } else {
                // create board space
            }
        }
    }
}
