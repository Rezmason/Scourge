package net.rezmason.scourge.textview;

import haxe.ds.StringMap;

import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.system.Capabilities;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;
using StringTools;
using Reflect;
using Lambda;

typedef Style = {
    @:optional var name:String;
    @:optional var basis:String;

    @:optional var r:Float;
    @:optional var g:Float;
    @:optional var b:Float;
    @:optional var i:Float;
    @:optional var s:Float;
    @:optional var p:Float;
}

class UIBody extends Body {

    inline static var ease:Float = 0.6;

    static var whitespaceReg:EReg = ~/([,\s]+)/g;
    static var colonReg:EReg = ~/\s*:\s*/g;
    static var styleTagsReg:EReg = ~/§\{[^\}]*\}/g;

    var styleIDs:Int;
    var orderedStyles:Array<Style>;

    var text:String;
    var page:Array<String>;
    var lineStyleIndices:Array<Int>;

    var defaultStyle:Style;

    /*
    inline static var BOX_SIGIL:String = "ß";
    inline static var LINE_SIGIL:String = "¬";
    */

    inline static var NATIVE_DPI:Float = 72;
    inline static var GLYPH_HEIGHT_IN_POINTS:Float = 18;
    var glyphWidthInPixels :Float;
    var glyphHeightInPixels:Float;
    var baseTransform:Matrix3D;

    var scrollFraction:Float;
    var scroll:Float;
    var scrollGoal:Float;
    var smoothScrolling:Bool;

    var numRows:Int;
    var numCols:Int;
    var numRowsForLayout:Int;
    var numGlyphsInLayout:Int;

    override function init():Void {

        defaultStyle = { name:"", r:1, g:1, b:1, i:0, s:1, p:0, };

        baseTransform = new Matrix3D();
        baseTransform.appendScale(1, -1, 1);

        letterbox = false;

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
        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        numRows = Std.int(rect.height * stageHeight / glyphHeightInPixels);
        numRowsForLayout = numRows;
        numRows++;
        numCols = Std.int(rect.width  * stageWidth  / glyphWidthInPixels );
        scrollFraction = 1 / numRowsForLayout;
        setGlyphScale(rect.width / numCols * 2, rect.height / numRowsForLayout * 2);

        reorderGlyphs();
        updateText(text);
    }

    public function updateText(text:String):Void {
        if (text == null) text = "";
        this.text = text;

        if (numGlyphsInLayout == 0) return;

        var styledLineReg:EReg = new EReg('((.§*){$numCols})', 'g');
        var lineToken:String = "ª÷º";
        var blankParagraph:String = "".rpad(" ", numCols);

        orderedStyles = [defaultStyle].concat(extractOrderedStyles(text));

        text = styleTagsReg.replace(text, "§");

        function padLine(s) return StringTools.rpad(s, " ", numCols + s.split("§").length - 1);
        function wrapLines(s) return styledLineReg.replace(s, '$1$lineToken').split(lineToken).map(padLine).join(lineToken);

        page = text.split("\n").map(wrapLines).join(lineToken).split(lineToken);
        while (page.length < numRows) page.push(blankParagraph);

        lineStyleIndices = [0];
        for (line in page) lineStyleIndices.push(line.split("§").length - 1);

        scrollChars(1, false);
    }

    function extractOrderedStyles(input:String):Array<Style> {

        // Find the tags in the input string

        var tags:Array<Array<String>> = [];
        for (str in input.split("§{")) {
            if (str.length == 0) continue;
            var tagEndIndex:Int = str.indexOf("}");
            if (tagEndIndex == -1) throw 'You left a style tag open, friend: ( $str )';
            tags.push(cleanTag(str.substr(0, tagEndIndex)));
        }

        // Interpret the tags– they are either declarations or references to existing, named declarations

        styleIDs = 0;
        var stylesByIndex:Array<Style> = [];
        var styles:Array<Style> = [];
        var stylesByID:StringMap<Style> = new StringMap<Style>();

        // Find (and remove) declarative tags and create styles from them

        for (ike in 0...tags.length) {
            var tag:Array<String> = tags[ike];
            if (tag.length > 1 || tag[0].indexOf(":") != -1) {
                var style:Style = makeStyle(tag);
                stylesByIndex[ike] = style;
                styles.push(style);
                if (style.name != null) stylesByID.set(style.name, style);

                tags[ike] = null;
            }
        }

        stylesByID.set("", defaultStyle);

        // styles inherit from their basis styles (no multiple inheritence)

        for (style in styles) {
            var topStyle:Style = style;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(topStyle.name);

                if (topStyle.basis == null) break;
                if (dependencyStack.has(topStyle.basis)) throw 'Cyclical style dependency, pal: ( $dependencyStack )';

                topStyle = stylesByID.get(topStyle.basis);
                if (topStyle == null) break;
            }

            while (dependencyStack.length > 0) {
                topStyle = stylesByID.get(dependencyStack.pop());

                if (topStyle != null) {
                    inheritStyle(topStyle, stylesByID.get(topStyle.basis));
                    topStyle.deleteField("basis");
                }
            }
        }

        // All styles inherit from the default style

        for (style in styles) inheritStyle(style, defaultStyle);

        // Resolve remaining tags, which are reference tags

        for (ike in 0...tags.length) {
            var tag:Array<String> = tags[ike];
            if (tag != null) {
                var style:Style = stylesByID.get(tag[0]);
                if (style == null) style = defaultStyle;
                stylesByIndex[ike] = style;
            }
        }

        return stylesByIndex;
    }

    inline function cleanTag(tagString:String):Array<String> {
        tagString = whitespaceReg.replace(tagString, " ");
        tagString = colonReg.replace(tagString, ":");
        tagString = StringTools.trim(tagString);

        return tagString.split(" ");
    }

    inline function makeStyle (tag:Array<String>):Style {
        var style:Style = {};
        for (attribute in tag) {
            var elements:Array<String> = attribute.split(":");
            var key:String = elements[0];
            var value:String = elements[1];

            switch (key) {
                case "name": style.name = value;
                case "basis": style.basis = value;
                default:
                    style.setField(key, Std.parseFloat(value));
            }
        }

        if (style.name == null) style.name = "style" + styleIDs++;

        return style;
    }

    inline function inheritStyle(style:Style, parentStyle:Style):Void {
        for (field in parentStyle.fields()) {
            if (field == "name" || field == "basis") continue;
            if (style.field(field) == null) style.setField(field, parentStyle.field(field));
        }
    }

    function setScroll(pos:Float):Void {
        var scrollStart:Int = Std.int(pos);
        var id:Int = 0;
        var pageSegment:Array<String> = page.slice(scrollStart, scrollStart + numRows);
        var styleIndex:Int = lineStyleIndices[scrollStart];
        var currentStyle:Style = orderedStyles[styleIndex];
        for (line in pageSegment) {
            var index:Int = 0;
            while (index < line.length) {
                if (line.charAt(index) == "§") {
                    currentStyle = orderedStyles[++styleIndex];
                    if (currentStyle == null) currentStyle = defaultStyle;
                } else {
                    var glyph:Glyph = glyphs[id++];
                    glyph.set_char(line.charCodeAt(index), glyphTexture.font);
                    glyph.set_color(currentStyle.r, currentStyle.g, currentStyle.b);
                    glyph.set_i(currentStyle.i);
                    glyph.set_s(currentStyle.s);
                    glyph.set_p(currentStyle.p);
                }
                index++;
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
        updateScroll();
        super.update();
    }

    inline function updateScroll():Void {
        if (smoothScrolling) {
            if (Math.abs(scrollGoal - scroll) < 0.0001) {
                scroll = scrollGoal;
                smoothScrolling = false;
            } else {
                scroll = scroll * ease + scrollGoal * (1 - ease);
            }

            setScroll(scroll);
        }
    }

    inline function reorderGlyphs():Void {
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
    }
}
