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
    // var backSheet:MatrixSheet;
    var frontSheet:MatrixSheet;

    public function new():Void {

        var chars = Strings.MATRIX_CHARS;
        var charCodes = [for (ike in 0...Utf8.length(chars)) Utf8.charCodeAt(chars, ike)];

        var fontManager:FontManager = new Present(FontManager);
        var matrixFont = fontManager.getFontByName('matrix');
        // backSheet = new MatrixSheet(matrixFont, charCodes, 80, 80, true);
        frontSheet = new MatrixSheet(matrixFont, charCodes, 60, 60);
        body = new Body();
        // body.addChild(backSheet.body);
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

    var columns:Array<MatrixColumn>;
    public var body(default, null):Body;

    public function new(font, charCodes, numRows:UInt, numColumns:UInt, isBackground:Bool = false):Void {
        body = new Body();
        body.updateSignal.add(update);
        body.glyphScale = 1 / Math.max(numRows, numColumns);
        body.glyphTexture = font;

        columns = [];

        var numLayers:UInt = isBackground ? 1 : 2;
        var glowCode = Utf8.charCodeAt('U', 0);

        body.growTo(numRows * numColumns * numLayers);
        for (column in 0...numColumns) {
            var frontGlyphs = [];
            var backGlyphs = [];
            for (row in 0...numRows) {
                var index = column * numRows + row;
                var frontGlyph = body.getGlyphByID(index * numLayers);
                var glyphX = column / (numColumns - 1) - 0.5;
                var glyphY = row / (numRows - 1) - 0.5;
                frontGlyph.SET({x:glyphX, y:glyphY});
                frontGlyphs.push(frontGlyph);
                if (!isBackground) {
                    var backGlyph = body.getGlyphByID(index * numLayers + 1);
                    backGlyph.SET({x:glyphX, y:glyphY, s:6, a:1, w:-0.5, char:glowCode});
                    backGlyphs.push(backGlyph);
                }
            }
            frontGlyphs.reverse();
            backGlyphs.reverse();
            columns.push(new MatrixColumn(charCodes, frontGlyphs, backGlyphs, isBackground ? 0.3 : 1.0));
        }

        var middleIndex = Std.int(columns.length * (0.5 + 0.3 * (Math.random() - 0.5)));
        var middleColumn = isBackground ? null : columns[middleIndex];
        for (column in columns) {
            // if (column != middleColumn) column.position = -Math.random() * numRows;
        }

        update(0);
    }

    function update(delta:Float) {
        for (column in columns) column.update(delta);
    }
}

class MatrixColumn {

    var frontGlyphs:Array<Glyph>;
    var backGlyphs:Array<Glyph>;
    var numGlyphs:UInt;
    var cycles:Array<Float>;
    var charCodes:Array<UInt>;
    var numChars:UInt;
    var brightness:Float;
    
    public var position:Float;
    var decay:Float;
    var speed:Float;

    public function new(charCodes, frontGlyphs, backGlyphs, brightness) {
        this.charCodes = charCodes;
        this.numChars = this.charCodes.length;
        this.frontGlyphs = frontGlyphs;
        this.backGlyphs = backGlyphs;
        numGlyphs = frontGlyphs.length;
        this.brightness = brightness;
        cycles = [for (ike in 0...numGlyphs) Math.random()];
        
        position = 0;
        decay = 2 + Math.random() * 3;
        speed = 0.3 + Math.random() * 0.3;
    }

    public function update(delta:Float) {
        position = position + delta * speed;
        if (position > 1) position = position % 1;

        for (ike in 0...numGlyphs) {
            var val = 0.0;
            var disp = ike / numGlyphs - position;
            if (disp < 0) {
                val = 1 + disp * decay;
                if (val < 0) val = 0;
            }

            var vitality = 1 - Math.pow(1 - val, 5);
            var sting = Math.pow(val, 2);

            cycles[ike] = (cycles[ike] + delta * 0.06 * (1 - vitality * 0.5)) % 1;
            var index = Std.int(numChars * cycles[ike]);
            
            var frontGlyph = frontGlyphs[ike];
            frontGlyph.set_char(charCodes[index]);

            frontGlyph.set_r(brightness * 0.4 * sting * sting);
            frontGlyph.set_g(brightness * vitality);
            frontGlyph.set_b(brightness * 0.4 * sting);
            frontGlyph.set_a((val - 0.5) * 0.5);

            var backGlyph = backGlyphs[ike];
            if (backGlyph != null) {
                backGlyph.set_a(sting);
                backGlyph.set_r(0.06 * brightness * 0.4 * sting * sting);
                backGlyph.set_g(0.06 * brightness * vitality);
                backGlyph.set_b(0.06 * brightness * 0.4 * sting);
            }
        }
    }
}
