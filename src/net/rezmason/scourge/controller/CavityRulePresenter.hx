package net.rezmason.scourge.controller;

using net.rezmason.scourge.textview.core.GlyphUtils;

class CavityRulePresenter extends RulePresenter {

    override function animateGlyphs() {
        if (spaceState.values[occupier_] != spaceState.lastValues[occupier_]) super.animateGlyphs();
    }
}
