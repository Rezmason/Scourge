package net.rezmason.scourge.controller;

using net.rezmason.scourge.textview.core.GlyphUtils;

class CavityRulePresenter extends RulePresenter {

    override function animateGlyphs():Bool {
        if (nodeState.values[occupier_] == nodeState.lastValues[occupier_]) return false;
        super.animateGlyphs();
        return true;
    }
}
