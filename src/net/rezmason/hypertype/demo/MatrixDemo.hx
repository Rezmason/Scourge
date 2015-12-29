package net.rezmason.hypertype.demo;

import haxe.Utf8;
import net.rezmason.gl.GLTypes;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class MatrixDemo {

    public var body(default, null):Body;
    var frontSheet:MatrixSheet;

    public function new():Void {
        var fontManager:FontManager = new Present(FontManager);
        var matrixFont = fontManager.getFontByName('matrix');
        frontSheet = new MatrixSheet(matrixFont);
        body = new Body();
        body.addChild(frontSheet.body);
        body.interactionSignal.add(receiveInteraction);
    }

    function receiveInteraction(id:Int, interaction:Interaction):Void {
        switch (interaction) {
            case MOUSE(type, x, y):
                switch (type) {
                    case MOVE, ENTER, EXIT: trace('$x $y');
                    case _:
                }
            case _:
        }
    }
}

class MatrixSheet {

    inline static var NUM_ROWS = 60;
    inline static var NUM_COLUMNS = 60;
    inline static var CHAR_CYCLE_SPEED = 0.03;
    
    inline static var CHARS = Strings.MATRIX_CHARS;
    static var NUM_CHARS = Utf8.length(CHARS);
    static var CHAR_CODES = [for (ike in 0...NUM_CHARS) Utf8.charCodeAt(CHARS, ike)];

    var glyphPhases:Array<Float>;
    var strips:Array<MatrixStrip>;
    var time:Float;

    public var body(default, null):Body;

    public function new(font):Void {
        body = new Body();
        body.updateSignal.add(update);
        body.glyphScale = 1 / Math.max(NUM_ROWS, NUM_COLUMNS);
        body.glyphTexture = font;

        strips = [];
        glyphPhases = [];

        body.growTo(NUM_ROWS * NUM_COLUMNS);
        for (column in 0...NUM_COLUMNS) {
            var glyphsInColumn = [];
            for (row in 0...NUM_ROWS) {
                var glyph = body.getGlyphByID(column * NUM_ROWS + row);
                glyph.SET({x:row / (NUM_ROWS - 1) - 0.5, y:column / (NUM_COLUMNS - 1) - 0.5});
                glyphsInColumn.push(glyph);
                glyphPhases[glyph.id] = Math.random();
            }
            strips.push(new MatrixStrip(glyphsInColumn));
        }

        time = 0;
        update(0);
    }

    function update(delta:Float) {
        time += delta;
        for (glyph in body.eachGlyph()) {
            var index = Std.int(NUM_CHARS * ((time * CHAR_CYCLE_SPEED + glyphPhases[glyph.id]) % 1));
            glyph.set_char(CHAR_CODES[index]);
        }
    }
}

class MatrixStrip {

    var glyphs:Array<Glyph>;

    public function new(glyphs:Array<Glyph>) {
        this.glyphs = glyphs;
    }
}
