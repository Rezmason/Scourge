package net.rezmason.scourge.pages;

import lime.math.Rectangle;
import lime.math.Vector4;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.Strings;
import net.rezmason.hypertype.core.Container;
import net.rezmason.hypertype.ui.TextLabel;
import net.rezmason.scourge.ScourgeColorPalette.*;

using net.rezmason.hypertype.core.GlyphUtils;

class SplashPage extends NavPage {

    inline static var h:String = Strings.HARD_SPACE;

    inline static var BUTTON_STYLE:String = 
    '§{name:splashUp,   p: 0.00, w: 0.0, r:0.7, g:0.7, b:0.7}' +
    '§{name:splashOver, p:-0.01, w: 0.1, r:0.9, g:0.9, b:0.9}' +
    '§{name:splashDown, p: 0.01, w:-0.1, r:0.5, g:0.5, b:0.5}' +
    'µ{name:splashButton, up:splashUp, over:splashOver, down:splashDown, period:0.2, i:1}§{}' +
    '¶{name:main, align:center}';

    var splashDemo:SplashDemo;
    var nav:Container;

    public function new():Void {
        super();

        splashDemo = new SplashDemo();
        splashDemo.body.glyphScale = 0.25;
        splashDemo.body.transform.appendRotation(-40, Vector4.X_AXIS);
        container.addChild(splashDemo.body);

        nav = new Container();
        nav.transform.appendTranslation(4, 4, 0);
        container.addChild(nav);

        var box = new net.rezmason.hypertype.ui.BorderBox();
        container.addChild(box.body);
        box.width = 4;
        box.height = 3;
        box.redraw();
        container.addChild(box.body);
        box.body.transform.appendTranslation(1, 1, 0);

        var label = new TextLabel();
        label.text = 'Oberon';
        label.align = CENTER;
        label.style.set_color(TEAM_COLORS[0]);
        label.style.set_i(0.8);
        label.redraw();
        label.body.transform.appendScale(2, 2, 1);
        label.body.transform.appendTranslation(6, 6, 0);
        container.addChild(label.body);

        var beginButton = makeButton('BEGIN', playGame);
        var aboutButton = makeButton('ABOUT', aboutGame);
        var leaveButton = makeButton('LEAVE', quitGame);

        nav.addChild(beginButton.body);
        nav.addChild(aboutButton.body);
        nav.addChild(leaveButton.body);
        beginButton.body.transform.appendTranslation(-5, 0, 0);
        leaveButton.body.transform.appendTranslation( 5, 0, 0);
    }

    public function makeButton(text:String, cbk:Void->Void):TextLabel {
        var label = new TextLabel();
        label.text = text;
        label.align = CENTER;
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
