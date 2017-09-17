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

        var splashContainer = new Container();
        splashContainer.boundingBox.set({
            width:REL(1),
            height:REL(0.5),
            align:CENTER,
            verticalAlign:MIDDLE,
            scaleMode:WIDTH_FIT
        });
        splashContainer.boxed = true;
        container.addChild(splashContainer);

        splashDemo = new SplashDemo();
        splashContainer.addChild(splashDemo.body);

        nav = new Container();
        nav.boundingBox.set({
            align:CENTER,
            verticalAlign:MIDDLE,
            width:ABS(4),
            height:ABS(4),
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
    }

    public function makeButton(text:String, cbk:Void->Void):TextLabel {
        var label = new TextLabel();
        label.text = text;
        label.textAlign = SIMPLE(CENTER);
        label.style.set_color(GREY);
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
