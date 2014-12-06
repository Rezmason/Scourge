package net.rezmason.scourge.textview.pages;

import flash.geom.Rectangle;
import openfl.Assets;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.ui.UIElement;
import net.rezmason.scourge.textview.ui.UIMediator;

class AboutPage extends NavPage {

    inline static var h:String = Strings.HARD_SPACE;

    inline static var BUTTON_STYLE:String = 
    '§{name:aboutUp,   p: 0.00, f:0.5, r:0.7, g:0.7, b:0.7}' +
    '§{name:aboutOver, p:-0.01, f:0.6, r:0.9, g:0.9, b:0.9}' +
    '§{name:aboutDown, p: 0.01, f:0.4, r:0.5, g:0.5, b:0.5}' +
    'µ{name:aboutButton, up:aboutUp, over:aboutOver, down:aboutDown, period:0.2, i:1}§{}' +
    '¶{name:nav, align:justify-center}' +
    '¶{name:paper, align:center}';

    var paper:UIElement;
    var paperMed:UIMediator;
    var nav:UIElement;
    var navMed:UIMediator;

    public function new():Void {
        super();

        paperMed = new UIMediator();
        paper = new UIElement(paperMed);
        paper.setFontSize(14);
        paper.scene.camera.rect = new Rectangle(0.1, 0, 0.8, 0.9);
        paper.scene.addBody(paper.body);
        scenes.push(paper.scene);

        navMed = new UIMediator();
        nav = new UIElement(navMed);
        nav.setFontSize(14);
        nav.scene.camera.rect = new Rectangle(0, 0.9, 1, 0.1);
        nav.scene.addBody(nav.body);
        scenes.push(nav.scene);

        var buttons:Array<String> = [
            makeButton('PREV', prev),
            makeButton('BACK', goBack),
            makeButton('NEXT', next),
        ];
        buttons.join('  ');

        var paperText:String = Assets.getText('text/about.txt');
        paperMed.setText(BUTTON_STYLE + paperText);

        var navText:String = '¶{nav}' + buttons.join('  ');
        navMed.setText(BUTTON_STYLE + navText);
    }

    public function makeButton(text:String, cbk:Void->Void):String {
        var id:String = 'button_' + text;
        paperMed.mouseSignal.add(function(str, type) if (str == id && type == CLICK) cbk());
        navMed.mouseSignal.add(function(str, type) if (str == id && type == CLICK) cbk());
        return 'µ{name:aboutButton, id:$id}$h$h$h$text$h$h$h§{}';
    }

    private function prev():Void {
        
    }

    private function next():Void {
        
    }

    private function goBack():Void {
        trace('!');
        navToSignal.dispatch(Back);
    }
}
