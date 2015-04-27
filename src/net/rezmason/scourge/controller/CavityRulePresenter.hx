package net.rezmason.scourge.controller;

using net.rezmason.scourge.textview.core.GlyphUtils;

class CavityRulePresenter extends RulePresenter {

    override function animateGlyphs() {
        if (nodeState.values[occupier_] != nodeState.lastValues[occupier_]) super.animateGlyphs();
    }
}
