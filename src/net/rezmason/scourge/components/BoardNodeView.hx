package net.rezmason.scourge.components;

import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.scourge.game.build.PetriTypes;
import net.rezmason.scourge.textview.core.Glyph;

class BoardNodeView {
    public var locus:GridLocus<PetriData>;
    public var over:Glyph;
    public var top:Glyph;
    public var bottom:Glyph;
}
