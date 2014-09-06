package net.rezmason.scourge.textview.pages;

import flash.geom.Rectangle;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.ui.SplashBody;
import net.rezmason.scourge.textview.ui.UIBody;
import net.rezmason.scourge.textview.ui.UIMediator;

class SplashPage extends NavPage {

    inline static var h:String = Strings.HARD_SPACE;

    inline static var BUTTON_STYLE:String = 
    '§{name:splashUp,   p: 0.00, f:0.5, r:0.7, g:0.7, b:0.7}' +
    '§{name:splashOver, p:-0.01, f:0.6, r:0.9, g:0.9, b:0.9}' +
    '§{name:splashDown, p: 0.01, f:0.4, r:0.5, g:0.5, b:0.5}' +
    'µ{name:splashButton, up:splashUp, over:splashOver, down:splashDown, period:0.2, i:1}§{}' +
    '¶{name:main, align:center}';

    var splashBody:SplashBody;
    var uiBody:UIBody;
    var uiMed:UIMediator;

    public function new():Void {
        super();

        splashBody = new SplashBody();
        splashBody.viewRect = new Rectangle(0.0, 0.0, 1.0, 0.4);
        bodies.push(splashBody);

        uiMed = new UIMediator();
        uiBody = new UIBody(uiMed);
        var uiRect:Rectangle = new Rectangle(0.0, 0.4, 1.0, 0.6);
        uiRect.inflate(-0.02, -0.02);
        uiBody.viewRect = uiRect;
        uiBody.setFontSize(28);
        bodies.push(uiBody);

        var buttons:Array<String> = [
            makeButton('BEGIN', playGame),
            makeButton('ABOUT', aboutGame),
            makeButton('LEAVE', quitGame),
        ];

        var uiText:String = BUTTON_STYLE + buttons.join('  ');
        uiMed.setText(uiText);
    }

    public function makeButton(text:String, cbk:Void->Void):String {
        var id:String = 'button_' + text;
        uiMed.mouseSignal.add(function(str, type) if (str == id && type == CLICK) cbk());
        return 'µ{name:splashButton, id:$id}$h$h$h$text$h$h$h§{}';
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
