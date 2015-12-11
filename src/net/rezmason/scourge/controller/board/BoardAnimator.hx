package net.rezmason.scourge.controller.board;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.View;
import net.rezmason.scourge.components.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class BoardAnimator {

    var view:View;
    var board:Body;
    var ecce:Ecce;
    var qAnimations:Query;
    var time:Float;

    public var animCompleteSignal(default, null):Zig<Void->Void> = new Zig();

    public function new():Void {
        ecce = new Present(Ecce);
        view = new Present(View);
        board = view.board;
        qAnimations = ecce.query([GlyphAnimation]);
    }

    public function wake() {
        time = 0;
        board.updateSignal.add(update);
        update(0);
    }

    public function cancel() board.updateSignal.remove(update);

    function update(delta:Float):Void {
        time += delta;

        var count = 0;
        for (e in qAnimations) {
            count++;
            var anim = e.get(GlyphAnimation);
            if (anim.startTime < time) {
                var percent = (time - anim.startTime) / anim.duration;
                var frac = anim.ease(percent);
                var view = anim.subject.get(BoardSpaceView);
                if (percent >= 1) {
                    view.top.copyFrom(anim.topTo);
                    view.bottom.copyFrom(anim.bottomTo);
                    anim.subject = null;
                    ecce.collect(e);
                    count--;
                } else {
                    interpolate(view.top,    anim.topFrom,    anim.topTo,    frac);
                    interpolate(view.bottom, anim.bottomFrom, anim.bottomTo, frac);
                }
            }
        }

        if (count == 0) {
            board.updateSignal.remove(update);
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
            // U
            // V
            // i:from.get_i() * inv + to.get_i() * frac,
            f:from.get_f() * inv + to.get_f() * frac,
            a:from.get_a() * inv + to.get_a() * frac,
            x:from.get_x() * inv + to.get_x() * frac,
            y:from.get_y() * inv + to.get_y() * frac,
            z:from.get_z() * inv + to.get_z() * frac,
            // CH
            // CV
            // h:from.get_h() * inv + to.get_h() * frac,
            s:from.get_s() * inv + to.get_s() * frac,
            p:from.get_p() * inv + to.get_p() * frac,
        });

        var fromChar = from.get_char();
        var toChar = to.get_char();
        if (fromChar != toChar) glyph.set_f(Math.abs(frac - 0.5));
        glyph.set_char(frac < 0.5 ? fromChar : toChar);
    }
}
