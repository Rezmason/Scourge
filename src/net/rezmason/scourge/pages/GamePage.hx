package net.rezmason.scourge.pages;

import lime.math.Rectangle;
import net.rezmason.scourge.View;
import net.rezmason.scourge.useractions.PlayGameAction;
import net.rezmason.hypertype.console.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Scene;
import net.rezmason.hypertype.demo.*;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.ui.UIElement;
import net.rezmason.hypertype.useractions.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

class GamePage extends NavPage {

    var bodiesByName:Map<String, Body>;
    var currentBodyName:String;
    var consoleMed:ConsoleUIMediator;
    var mainScene:Scene;

    public function new():Void {
        super();

        mainScene = new Scene();
        mainScene.camera.glyphScaleMode = SCALE_WITH_MIN;
        scenes.push(mainScene);
        
        consoleMed = new ConsoleUIMediator();
        var interpreter = new Interpreter(consoleMed);
        var console:UIElement = new UIElement(consoleMed);

        var alphabetDemo:AlphabetDemo = new AlphabetDemo();
        var glyphDemo:GlyphDemo = new GlyphDemo();
        var eyeCandyDemo:EyeCandyDemo = new EyeCandyDemo();
        var matrixDemo:MatrixDemo = new MatrixDemo();
        var view:View = new Present(View);

        bodiesByName = new Map();
        bodiesByName['alphabet'] = alphabetDemo.body;
        bodiesByName['sdf']      = glyphDemo.body;
        bodiesByName['test']     = eyeCandyDemo.body;
        bodiesByName['matrix']   = matrixDemo.body;
        bodiesByName['board']    = view.body;

        // console.hasScrollBar = true;
        console.scene.camera.rect = new Rectangle(0, 0, 0.5, 0.5);
        scenes.push(console.scene);

        interpreter.addAction(new SetFontAction(console));
        interpreter.addAction(new SetLayoutAction(console));
        interpreter.addAction(new SetNameAction(interpreter));
        interpreter.addAction(new PrintAction());
        interpreter.addAction(new PlayGameAction(showBodyByName.bind('board')));
        
        interpreter.addAction(new SimpleAction('clear', function (args, outputSignal) {
            consoleMed.clearText();
            outputSignal.dispatch(null, true);
        }));

        interpreter.addAction(new SimpleAction('show', function (args, outputSignal) {
            var bodyName:String = args.tail;
            var message:String = null;
            if (bodiesByName[bodyName] != null) {
                showBodyByName(bodyName);
                message = 'Showing $bodyName.';
            } else {
                message = ConsoleUtils.styleError('"$bodyName" not found.');
            }
            outputSignal.dispatch(message, true);
        }));

        showBodyByName('board');
    }

    function showBodyByName(name:String):Void {
        if (currentBodyName != null) mainScene.root.removeChild(bodiesByName[currentBodyName]);
        currentBodyName = name;
        mainScene.root.addChild(bodiesByName[currentBodyName]);
        mainScene.focus = bodiesByName[currentBodyName];
    }
}
