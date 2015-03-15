package net.rezmason.scourge.components;

import net.rezmason.ecce.Entity;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class GlyphAnimation {

    public var index:Int;
    public var duration:Float;
    public var overlap:Float;
    public var startTime:Float;
    public var time:Float;
    public var subject:Entity;
    
    public var topFrom:Glyph;
    public var topTo:Glyph;

    public var bottomFrom:Glyph;
    public var bottomTo:Glyph;

    public var ease:Float->Float;

    function copyFrom(other:GlyphAnimation) {
        if (other != null) {
            var otherGA:GlyphAnimation = cast other;
            time = otherGA.time;
            index = otherGA.index;
            duration = otherGA.duration;
            overlap = otherGA.overlap;
            startTime = otherGA.startTime;
            subject = otherGA.subject;
            ease = otherGA.ease;

            if (otherGA.topFrom != null) topFrom = otherGA.topFrom.copy();
            if (otherGA.topTo   != null) topTo   = otherGA.topTo.copy();

            if (otherGA.bottomFrom != null) bottomFrom = otherGA.bottomFrom.copy();
            if (otherGA.bottomTo   != null) bottomTo   = otherGA.bottomTo.copy();
        }
    }
}
