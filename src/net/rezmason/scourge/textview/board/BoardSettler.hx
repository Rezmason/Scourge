package net.rezmason.scourge.textview.board;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Query;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.textview.core.Body;

import net.kawa.tween.easing.*;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.praxis.grid.GridUtils;

class BoardSettler {

    var body:Body;
    var ecce:Ecce;
    var qBoardViews:Query;

    public function new(ecce:Ecce, body:Body):Void {
        this.ecce = ecce;
        this.body = body;
        qBoardViews = ecce.query([BoardNodeView]);
    }

    public function run() {
        for (entity in qBoardViews) {
            var view = entity.get(BoardNodeView);
            if (view.raised) {
                view.raised = false;
                var anim = ecce.dispense([GlyphAnimation]).get(GlyphAnimation);
                anim.subject = entity;
                if (anim.topFrom == null) anim.topFrom = GlyphUtils.createGlyph();
                if (anim.topTo == null) anim.topTo = GlyphUtils.createGlyph();
                if (anim.bottomFrom == null) anim.bottomFrom = GlyphUtils.createGlyph();
                if (anim.bottomTo == null) anim.bottomTo = GlyphUtils.createGlyph();
                anim.duration = 0.3;
                anim.ease = Quad.easeInOut;
                
                anim.topFrom.copyFrom(view.top);
                anim.topTo.copyFrom(view.top);
                anim.bottomFrom.copyFrom(view.bottom);
                anim.bottomTo.copyFrom(view.bottom);

                anim.topTo.set_p(-0.01);
                // TODO: nudge logic
            }
        }
    }
}
