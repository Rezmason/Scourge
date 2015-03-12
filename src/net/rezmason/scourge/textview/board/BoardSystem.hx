package net.rezmason.scourge.textview.board;

import net.rezmason.ecce.Ecce;
// import net.rezmason.scourge.controller.Sequencer;
// import net.rezmason.scourge.controller.RulePresenter;
// import net.rezmason.scourge.game.ScourgeConfig;
import net.rezmason.scourge.game.build.PetriTypes;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Body;

using net.rezmason.scourge.textview.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class BoardSystem {

    var board:Body;
    var ecce:Ecce;

    public function new(board:Body, ecce:Ecce):Void {
        this.board = board;
        this.ecce = ecce;
    }

    public function buildBoard(loci:Array<PetriLocus>):Void {
        board.growTo(loci.length);

        var maxDistSquared:Float = 0;

        for (locus in loci) {
            var glyph = board.getGlyphByID(locus.id);
            glyph.set_char('+'.code());
            glyph.set_color(BOARD_COLOR);
            var pos = locus.value.pos;
            glyph.set_pos(pos);
            var distSquared = pos.x * pos.x + pos.y * pos.y + pos.z * pos.z;
            if (maxDistSquared < distSquared) maxDistSquared = distSquared;
        }

        board.transform.identity();
        var scale = 0.8 / Math.sqrt(maxDistSquared * 2);
        board.transform.appendScale(scale, scale, scale);
        board.glyphScale = scale * 0.8;
    }
}
