package net.rezmason.scourge.pages;

import lime.math.Rectangle;
import lime.math.Vector4;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.Strings;
import net.rezmason.hypertype.core.Container;
import net.rezmason.hypertype.ui.TextLabel;
import net.rezmason.hypertype.ui.TextBox;
import net.rezmason.scourge.ScourgeColorPalette.*;

using net.rezmason.hypertype.core.GlyphUtils;

class SplashPage extends NavPage {

    var splashDemo:SplashDemo;
    var nav:Container;

    public function new():Void {
        super();

        splashDemo = new SplashDemo();
        splashDemo.container.boundingBox.set({
            left:REL(0.08),
            right:REL(0.08),
            top:REL(0.08),
            bottom:REL(0.5),
            align:CENTER,
            verticalAlign:MIDDLE,
            scaleMode:WIDTH_FIT
        });
        container.addChild(splashDemo.container);

        nav = new Container();
        nav.boundingBox.set({
            align:CENTER,
            verticalAlign:MIDDLE,
            width:REL(1),
            height:REL(0.5),
            bottom:ZERO,
            // scaleMode:WIDTH_FIT;
        });
        nav.boxed = true;
        container.addChild(nav);

        var beginButton = makeButton('BEGIN', playGame);
        var aboutButton = makeButton('ABOUT', aboutGame);
        var leaveButton = makeButton('LEAVE', quitGame);

        nav.addChild(beginButton.body);
        nav.addChild(aboutButton.body);
        nav.addChild(leaveButton.body);

        aboutButton.body.transform.appendTranslation( 0, 0, 0);
        beginButton.body.transform.appendTranslation(-6, 0, 0);
        leaveButton.body.transform.appendTranslation( 6, 0, 0);
    }

    public function makeButton(text:String, cbk:Void->Void):TextLabel {
        var label = new TextLabel();
        label.text = text;
        label.textAlign = SIMPLE(CENTER);
        label.verticalAlign = MIDDLE;
        label.style.set_color(GREY);
        label.glyphWidth = 0.75;
        label.redraw();
        label.body.interactionSignal.add(function(_, interaction) {
            switch (interaction) {
                case MOUSE(type, _, _):
                    switch (type) {
                        case CLICK: cbk();
                        case ENTER: 
                            label.style.SET({color:WHITE, w:0.3});
                            label.redraw();
                        case EXIT:
                            label.style.SET({color:GREY, w:0});
                            label.redraw();
                        case _:
                    }
                case _:
            }
        });
        return label;
    }

    private function playGame():Void {
        navToSignal.dispatch(Page(ScourgeNavPageAddresses.GAME));
    }

    private function quitGame():Void {
        navToSignal.dispatch(Gone);
    }

    private function aboutGame():Void {
        navToSignal.dispatch(Page(ScourgeNavPageAddresses.ABOUT));
    }
}
