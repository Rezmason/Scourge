package net.rezmason.scourge;

import net.rezmason.hypertype.core.Body;
import net.rezmason.math.Vec4;
import net.rezmason.scourge.ColorPalette.*;
import net.rezmason.scourge.ScourgeStrings.BITE_CODE;

using net.rezmason.hypertype.core.GlyphUtils;

class OriginPoint extends Body {

    public function new(color:Vec4 = null) {
        super();
        size = 1;
        if (color == null) color = WHITE;
        glyphs[0].SET({
            color:color,
            char:BITE_CODE
        });
    }
}
