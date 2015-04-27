package net.rezmason.scourge.components;

import net.rezmason.ecce.Entity;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class GlyphAnimation {
    public var duration:Float;
    public var startTime:Float;
    public var subject:Entity;
    
    public var topFrom:Glyph;
    public var topTo:Glyph;

    public var bottomFrom:Glyph;
    public var bottomTo:Glyph;

    public var ease:Float->Float;
}
