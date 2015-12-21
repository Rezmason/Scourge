package net.rezmason.scourge.pages;

import net.rezmason.gl.GLTypes;
import net.rezmason.hypertype.core.Interaction;
import net.rezmason.hypertype.core.Scene;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.ui.UIElement;
import net.rezmason.hypertype.ui.UIMediator;
import net.rezmason.hypertype.Strings;

class SplashPage extends NavPage {

    inline static var h:String = Strings.HARD_SPACE;

    inline static var BUTTON_STYLE:String = 
    '§{name:splashUp,   p: 0.00, f: 0.0, r:0.7, g:0.7, b:0.7}' +
    '§{name:splashOver, p:-0.01, f: 0.1, r:0.9, g:0.9, b:0.9}' +
    '§{name:splashDown, p: 0.01, f:-0.1, r:0.5, g:0.5, b:0.5}' +
    'µ{name:splashButton, up:splashUp, over:splashOver, down:splashDown, period:0.2, i:1}§{}' +
    '¶{name:main, align:center}';

    var splashScene:Scene;
    var splashDemo:SplashDemo;
    var nav:UIElement;
    var navMed:UIMediator;

    public function new():Void {
        super();

        splashDemo = new SplashDemo();
        splashScene = new Scene();
        splashScene.camera.scaleMode = WIDTH_FIT;
        splashScene.camera.rect = new Rectangle(0.0, 0.0, 1.0, 0.4);
        splashScene.root.addChild(splashDemo.body);
        scenes.push(splashScene);

        /*
        var box = new net.rezmason.hypertype.ui.BorderBox();
        var boxScene = new Scene();
        boxScene.camera.rect = new Rectangle(0, 0, 1, 1);
        boxScene.root.addChild(box.body);
        scenes.push(boxScene);
        box.width = 0.85;
        box.height = 0.75;
        box.redraw();
        */

        navMed = new UIMediator();
        nav = new UIElement(navMed);
        var uiRect:Rectangle = new Rectangle(0.0, 0.4, 1.0, 0.6);
        uiRect.inflate(-0.02, -0.02);
        nav.scene.camera.rect = uiRect;
        nav.setFontSize(28);
        scenes.push(nav.scene);

        var buttons:Array<String> = [
            makeButton('BEGIN', playGame),
            makeButton('ABOUT', aboutGame),
            makeButton('LEAVE', quitGame),
        ];

        var uiText:String = BUTTON_STYLE + buttons.join('  ');
        navMed.setText(uiText);
    }

    public function makeButton(text:String, cbk:Void->Void):String {
        var id:String = 'button_' + text;
        navMed.mouseSignal.add(function(str, type) if (str == id && type == CLICK) cbk());
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
