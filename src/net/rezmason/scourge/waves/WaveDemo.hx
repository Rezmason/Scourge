package net.rezmason.scourge.waves;

import net.rezmason.hypertype.demo.Demo;

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class WaveDemo extends Demo {

    var pool:WavePool = new WavePool(100);
    var bolus = WaveFunctions.bolus; // WaveFunctions.photocopy(bolus, 10);
    var heartbeat = WaveFunctions.heartbeat; // WaveFunctions.photocopy(heartbeat, 10);
    
    public function new() {
        super();
        pool.addRipple(new Ripple(bolus,     0.2, 20, 0.95, 30));
        pool.addRipple(new Ripple(bolus,     0.1, 10, 0.99,  6));
        pool.addRipple(new Ripple(heartbeat, 0.1, 15, 0.99, 15));

        body.size = pool.size;
        body.glyphScale = 0.01;
        for (glyph in body.eachGlyph()) glyph.SET({char:'•'.code(), x:glyph.id / pool.size - 0.5});
    }

    override function update(delta) {
        pool.update(delta);
        for (ike in 0...pool.size) body.getGlyphByID(ike).set_y(-pool.getHeightAtIndex(ike));
    }
}
