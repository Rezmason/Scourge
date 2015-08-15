package net.rezmason.scourge.textview.board;

import haxe.Utf8;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.Strings.*;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.grid.GridUtils;

class BoardAnimator {

    var body:Body;
    var ecce:Ecce;
    var qBoardView:Query;
    var qAnimations:Query;
    var time:Float;
    var speed:Float;

    public var animCompleteSignal(default, null):Zig<Void->Void> = new Zig();

    public function new(ecce:Ecce, body:Body, animateMils:Int):Void {
        this.ecce = ecce;
        this.body = body;
        speed = 1000 / animateMils;
        qBoardView = ecce.query([BoardSpaceView]);
        qAnimations = ecce.query([GlyphAnimation]);
    }

    public function init(_, _) {
        // First pass: tag and remove view from unnecessary walls, calculate approximate board radius
        var numSpacesThatMatter = 0;
        var trimmings:Map<Int, Bool> = new Map();
        var maxDistSquared:Float = 0;
        for (entity in qBoardView) {
            var cell = entity.get(BoardSpaceView).cell;
            if (cell.value.isWall) {
                var hasEmptyNeighbor = false;
                for (neighbor in cell.neighbors) {
                    if (neighbor != null && !neighbor.value.isWall) {
                        hasEmptyNeighbor = true;
                        break;
                    }
                }
                if (hasEmptyNeighbor) {
                    numSpacesThatMatter++;
                } else {
                    trimmings[cell.id] = true;
                    entity.remove(BoardSpaceView);
                }
            } else {
                numSpacesThatMatter++;
            }
            var pos = cell.value.pos;
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
        for (entity in qBoardView) {
            var view = entity.get(BoardSpaceView);
            var cell = view.cell;
            var pos = cell.value.pos;
            
            var bottom = view.bottom = body.getGlyphByID(itr + 0).reset().SET({pos:pos});
            var top    = view.top =    body.getGlyphByID(itr + 1).reset().SET({pos:pos, p:-0.03});
            var over   = view.over =   body.getGlyphByID(itr + 2).reset().SET({pos:pos, p: 0.06});

            if (cell.value.isWall) {
                top.set_color(WALL_COLOR);
                bottom.set_color(BOARD_COLOR);
                var numNeighbors:Int = 0;
                var bitfield:Int = 0;
                for (neighbor in cell.orthoNeighbors()) {
                    if (neighbor != null && !trimmings[neighbor.id] && neighbor.value.isWall) {
                        bitfield = bitfield | (1 << numNeighbors);
                    }
                    numNeighbors++;
                }
                top.set_char(Utf8.charCodeAt(BOX_SYMBOLS, bitfield));
                bottom.set_char(Utf8.charCodeAt(BOX_SYMBOLS, bitfield));

                top.set_h(body.glyphTexture.font.glyphRatio);
                bottom.set_h(body.glyphTexture.font.glyphRatio);
            } else {
                bottom.set_char(BOARD_CODE);
                bottom.set_color(BOARD_COLOR);
                top.set_color(BLACK);
            }
            itr += 3;
        }
    }

    public function wake() {
        time = 0;
        body.updateSignal.add(update);
        update(0);
    }

    function update(delta:Float):Void {
        time += delta * speed;

        var count = 0;
        for (e in qAnimations) {
            count++;
            var anim = e.get(GlyphAnimation);
            if (anim.startTime < time) {
                var percent = (time - anim.startTime) / anim.duration;
                var frac = anim.ease(percent);
                var view = anim.subject.get(BoardSpaceView);
                if (percent > 1) {
                    view.top.copyFrom(anim.topTo);
                    view.bottom.copyFrom(anim.bottomTo);
                    ecce.collect(e);
                    count--;
                } else {
                    interpolate(view.top,    anim.topFrom,    anim.topTo,    frac);
                    interpolate(view.bottom, anim.bottomFrom, anim.bottomTo, frac);
                }
            }
        }

        if (count == 0) {
            body.updateSignal.remove(update);
            animCompleteSignal.dispatch();
        }
    }

    function interpolate(glyph:Glyph, from:Glyph, to:Glyph, frac:Float):Void {
        if (frac > 1) frac = 1;
        else if (frac < 0) frac = 0;
        var inv = 1 - frac;
        glyph.SET({
            r:from.get_r() * inv + to.get_r() * frac,
            g:from.get_g() * inv + to.get_g() * frac,
            b:from.get_b() * inv + to.get_b() * frac,
            a:from.get_a() * inv + to.get_a() * frac,
            s:from.get_s() * inv + to.get_s() * frac,
            p:from.get_p() * inv + to.get_p() * frac,
        });

        if (from.get_char() != to.get_char()) glyph.set_f(Math.abs(frac - 0.5));
        var char:Int = frac < 0.5 ? from.get_char() : to.get_char();
        if (glyph.get_char() != char) glyph.set_char(char);
    }
}
