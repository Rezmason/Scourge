package net.rezmason.hypertype.demo;

import haxe.Utf8;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.FontManager;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class MatrixDemo extends Demo {

    // var backSheet:MatrixSheet;
    var frontSheet:MatrixSheet;

    public function new():Void {
        super();
        var chars = Strings.MATRIX_CHARS;
        var charCodes = [for (ike in 0...Utf8.length(chars)) Utf8.charCodeAt(chars, ike)];

        var fontManager:FontManager = new Present(FontManager);
        var matrixFont = fontManager.getFontByName('matrix');
        // backSheet = new MatrixSheet(matrixFont, charCodes, 80, 80, true);
        frontSheet = new MatrixSheet(matrixFont, charCodes, 60, 60);
        // body.addChild(backSheet.body);
        body.addChild(frontSheet.body);
    }

    override function receiveInteraction(id:Int, interaction:Interaction):Void {
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

    var columns:Array<MatrixColumn>;
    public var body(default, null):Body;

    public function new(font, charCodes, numRows:UInt, numColumns:UInt, isBackground:Bool = false):Void {
        body = new Body();
        body.updateSignal.add(update);
        body.glyphScale = 1 / Math.max(numRows, numColumns);
        body.font = font;

        columns = [];
        var glowCode = Utf8.charCodeAt('U', 0);

        body.growTo(numRows * numColumns);
        for (column in 0...numColumns) {
            var glyphs = [];
            for (row in 0...numRows) {
                var index = column * numRows + row;
                var glyph = body.getGlyphByID(index);
                var glyphX = column / (numColumns - 1) - 0.5;
                var glyphY = row / (numRows - 1) - 0.5;
                glyph.SET({x:glyphX, y:glyphY});
                glyphs.push(glyph);
            }
            glyphs.reverse();
            columns.push(new MatrixColumn(charCodes, glyphs, isBackground ? 0.1 : 1.0));
        }

        for (column in columns) column.position = -(column.speed + Math.random());
        if (!isBackground) {
            var middleColumn = columns[Std.int(columns.length * (0.5 + 0.3 * (Math.random() - 0.5)))];
            middleColumn.position = 0;
        }

        update(0);
    }

    function update(delta:Float) {
        for (column in columns) column.update(delta);
    }
}

class MatrixColumn {

    inline static var CYCLE_SPEED = 0.12;

    var glyphs:Array<Glyph>;
    var numGlyphs:UInt;
    var cycles:Array<Float>;
    var glyphIndices:Array<Int>;
    var charCodes:Array<Int>;
    var numChars:UInt;
    var brightness:Float;
    
    public var position:Float;
    var tailLength:Float;
    public var speed:Float;

    public function new(charCodes, glyphs, brightness) {
        this.charCodes = charCodes;
        this.numChars = this.charCodes.length;
        this.glyphs = glyphs;
        numGlyphs = glyphs.length;
        this.brightness = brightness;
        cycles = [for (ike in 0...numGlyphs) Math.random()];
        glyphIndices = [];
        reinitialize();
    }

    public function update(delta:Float) {
        position = position + delta * speed;
        if (position > 1 + tailLength) reinitialize();
        for (ike in 0...numGlyphs) {
            var glyph = glyphs[ike];
            var disp = ike / numGlyphs;
            var val = (disp - (position - tailLength)) / tailLength;
            if (val < 0 || val > 1) val = 0;
            if (val > 0) {
                cycles[ike] = (cycles[ike] + delta * CYCLE_SPEED * (1 - val)) % 1;
                var index = Std.int(numChars * cycles[ike]);
                if (glyphIndices[ike] != index) {
                    glyphIndices[ike] = index;
                    glyph.set_char(charCodes[index]);
                }
            }
            val *= brightness;
            glyph.SET({r:val * 0.1, g:val, b:val * 0.2, a:1 + val});
        }
    }

    function reinitialize() {
        tailLength = 0.2 + Math.random() * 0.6;
        speed = 0.4 + Math.random() * 0.4;
        position = -(speed * Math.random() * 0.5);
    }
}
