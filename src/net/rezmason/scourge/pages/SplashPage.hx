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
        // container.addChild(splashDemo.body);

        nav = new Container();
        nav.transform.appendTranslation(4, 4, 0);
        container.addChild(nav);

        var box = new net.rezmason.hypertype.ui.BorderBox();
        container.addChild(box.body);
        box.width = 4;
        box.height = 4;
        box.color = TEAM_COLORS[0];
        box.redraw();
        container.addChild(box.body);
        box.body.transform.appendTranslation(0, 0, 0);

        box = new net.rezmason.hypertype.ui.BorderBox();
        container.addChild(box.body);
        box.width = 4;
        box.height = 4;
        box.color = TEAM_COLORS[1];
        box.redraw();
        box.body.transform.appendTranslation(4, 4, 0);
        container.addChild(box.body);

        box = new net.rezmason.hypertype.ui.BorderBox();
        container.addChild(box.body);
        box.width = 4;
        box.height = 4;
        box.color = TEAM_COLORS[2];
        box.redraw();
        box.body.transform.appendTranslation(8, 8, 0);
        container.addChild(box.body);

        box = new net.rezmason.hypertype.ui.BorderBox();
        container.addChild(box.body);
        box.width = 4;
        box.height = 4;
        box.color = TEAM_COLORS[3];
        box.redraw();
        box.body.transform.appendRotation(45, Vector4.Z_AXIS);
        box.body.transform.appendTranslation(8, 0, 0);
        container.addChild(box.body);

        var textBox = new TextBox();
        textBox.width = 6;
        textBox.height = 4;
        textBox.glyphWidth = 0.5;
        textBox.text = 'one two three one two three';
        textBox.textAlign = SIMPLE(CENTER);
        textBox.verticalAlign = MIDDLE;
        textBox.style.set_color(TEAM_COLORS[1]);
        textBox.redraw();
        container.addChild(textBox.body);

        var label = new TextLabel();
        label.text = 'Oberon';
        label.textAlign = SIMPLE(CENTER);
        label.verticalAlign = MIDDLE;
        label.style.set_color(TEAM_COLORS[0]);
        label.style.set_i(0.8);
        label.redraw();
        container.addChild(label.body);
        
        var time = 0.;
        label.body.updateSignal.add(function(delta) {
            time += delta;
            label.body.transform.identity();
            // var scale = Math.sin(time / 100) * 1.5;
            // label.body.transform.appendScale(scale, scale, scale);
            label.body.transform.appendRotation(time * 10, Vector4.Z_AXIS);
            label.body.transform.appendTranslation(4, 4, 0);
        });

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
