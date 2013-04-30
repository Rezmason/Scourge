package net.rezmason.scourge.textview;

import haxe.ds.StringMap;

import com.adobe.utils.PerspectiveMatrix3D;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;
import nme.system.Capabilities;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;
using StringTools;

class UIBody extends Body {

    inline static var ease:Float = 0.6;

    var text:String;
    var page:Array<String>;
    var projection:PerspectiveMatrix3D;
    /*
    inline static var BOX_SIGIL:String = "ß";
    inline static var LINE_SIGIL:String = "¬";
    */

    inline static var NATIVE_DPI:Float = 72;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 24;
    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var scrollFraction:Float;
    var scroll:Float;
    var scrollGoal:Float;
    var smoothScrolling:Bool;

    var numRows:Int;
    var numCols:Int;
    var numGlyphsInLayout:Int;

    override function init():Void {

        projection = new PerspectiveMatrix3D();
        projection.perspectiveLH(2, 2, 1, 2);

        baseTransform = new Matrix3D();

        glyphHeightInPixels = GLYPH_HEIGHT_IN_POINTS * Capabilities.screenDPI / NATIVE_DPI;
        glyphWidthInPixels = glyphHeightInPixels / glyphTexture.font.glyphRatio;

        var numGlyphColumns:Int = Std.int(Capabilities.screenResolutionX / glyphWidthInPixels);
        var numGlyphRows:Int = Std.int(Capabilities.screenResolutionY / glyphHeightInPixels);

        var numGlyphs:Int = numGlyphRows * numGlyphColumns;
        var blank:Int = " ".charCodeAt(0);

        scroll = 0;
        scrollGoal = 0;
        smoothScrolling = false;

        //var sigils:EReg = ~/[ß¬]/;

        for (id in 0...numGlyphs) {
            var glyph:Glyph = new Glyph();
            glyph.visible = true;
            glyph.id = id;
            glyphs.push(glyph);

            var x:Float = 0;
            var y:Float = 0;

            /*
            var char:String = strMatrix[row][col];
            if (sigils.match(char)) {
                var left  :Int = (col > 0            && sigils.match(strMatrix[row][col - 1])) ? 1 : 0;
                var right :Int = (col < NUM_COLS - 1 && sigils.match(strMatrix[row][col + 1])) ? 1 : 0;
                var top   :Int = (row > 0            && sigils.match(strMatrix[row - 1][col])) ? 1 : 0;
                var bottom:Int = (row < NUM_ROWS - 1 && sigils.match(strMatrix[row + 1][col])) ? 1 : 0;

                if (char == LINE_SIGIL) {
                    if (left & right == 1) top = bottom = 0;
                    if (top & bottom == 1) left = right = 0;
                }

                var flag:Int = (left << 0) | (right << 1) | (top << 2) | (bottom << 3);
                char = TestStrings.BOX_SYMBOLS.charAt(flag);
            }

            var charCode:Int = char.charCodeAt(0);
            */

            glyph.makeCorners();
            glyph.set_shape(x, y, 0, 1, 0);
            glyph.set_color(1, 1, 1);
            glyph.set_i(0);
            glyph.set_char(blank, glyphTexture.font);
            glyph.set_paint(glyph.id);
        }
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {
        super.adjustLayout(stageWidth, stageHeight, rect);

        // sanitize the rect
        rect = rect.clone();
        if (stageWidth  == 0) stageWidth  = 1;
        if (stageHeight == 0) stageHeight = 1;
        if (rect.width  == 0) rect.width  = 1 / stageWidth;
        if (rect.height == 0) rect.height = 1 / stageHeight;

        var screenRatio:Float = stageWidth / stageHeight;

        // set the glyph transform and rearrange the characters
        var rectWidthInPixels :Float = rect.width  * stageWidth;
        var rectHeightInPixels:Float = rect.height * stageHeight;

        numRows = Std.int(rectHeightInPixels / glyphHeightInPixels);
        var numRowsForLayout:Int = numRows;
        numRows++;
        numCols = Std.int(rectWidthInPixels  / glyphWidthInPixels );

        scrollFraction = 1 / numRowsForLayout;

        var glyphWidth :Float = rectWidthInPixels  / stageWidth  / numCols;
        var glyphHeight:Float = rectHeightInPixels / stageHeight / numRowsForLayout;

        glyphTransform.identity();
        glyphTransform.appendScale(glyphWidth * 2, glyphHeight * 2, 1);

        baseTransform.identity();
        baseTransform.appendScale(1, -1, 1);

        var id:Int = 0;
        for (row in 0...numRows) {
            for (col in 0...numCols) {
                var x:Float = ((col + 0.5) / numCols - 0.5);
                var y:Float = ((row + 0.5) / numRowsForLayout - 0.5);
                var glyph:Glyph = glyphs[id++];
                glyph.set_pos(x, y, 0);
            }
        }

        numGlyphsInLayout = numRows * numCols;
        toggleGlyphs(glyphs.slice(0, numGlyphsInLayout), true);
        toggleGlyphs(glyphs.slice(numGlyphsInLayout), false);

        // prepend the letterbox
        /*
        var letterbox:Matrix3D = new Matrix3D();
        var boxRatio:Float = (rect.width / rect.height) / screenRatio;
        if (boxRatio < 1) letterbox.appendScale(1, boxRatio, 1);
        else letterbox.appendScale(1 / boxRatio, 1, 1);
        camera.prepend(letterbox);
        */

        camera.appendTranslation(0, 0, 1); // Set the camera back one unit
        camera.append(projection); // Apply perspective

        // offset the vanishing point to the rectangle's center
        var vec:Vector3D = new Vector3D();
        camera.copyColumnTo(2, vec);
        vec.x += (rect.left + rect.right  - 1);
        vec.y -= (rect.top  + rect.bottom - 1);
        camera.copyColumnFrom(2, vec);

        updateText(text);
        update();
    }

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        if (numGlyphsInLayout == 0) return;

        var fullLine:EReg = new EReg('(.{$numCols})', 'g');
        var token:String = "__TOKEN__";
        var blankParagraph:String = "".rpad(" ", numCols);

        function padLine(s) return StringTools.rpad(s, " ", numCols);
        function wrapLines(s) return fullLine.replace(s, '$1$token').split(token).map(padLine).join(token);

        page = text.split("\n").map(wrapLines).join(token).split(token);
        while (page.length < numRows) page.push(blankParagraph);

        scrollChars(1, false);
    }

    function setScroll(pos:Float):Void {
        var scrollStart:Int = Std.int(pos);
        var id:Int = 0;

        for (line in page.slice(scrollStart, scrollStart + numRows)) {
            var itr:Int = 0;
            while (itr < numCols) {
                if (false) {
                    // TODO: interpret sequence
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(line.charCodeAt(itr++), glyphTexture.font);
                }
            }
        }

        transform.identity();
        transform.append(baseTransform);
        transform.appendTranslation(0, (pos - scrollStart) * scrollFraction, 0);
    }

    public function scrollChars(ratio:Float, smoothScrolling:Bool = true):Void {
        var pos:Float = (page.length - (numRows - 1)) * (1 - Math.max(0, Math.min(1, ratio)));

        this.smoothScrolling = smoothScrolling;

        if (smoothScrolling) scrollGoal = Std.int(pos);
        else setScroll(pos);
    }

    override public function update():Void {
        if (smoothScrolling) {
            if (Math.abs(scrollGoal - scroll) < 0.0001) {
                scroll = scrollGoal;
                smoothScrolling = false;

            } else {
                scroll = scroll * ease + scrollGoal * (1 - ease);
            }

            setScroll(scroll);
        }

        super.update();
    }
}
