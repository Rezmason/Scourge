package net.rezmason.scourge.pages;

import net.rezmason.hypertype.console.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.SceneGraph;
import net.rezmason.hypertype.demo.*;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.useractions.*;
import net.rezmason.scourge.View;
import net.rezmason.scourge.useractions.PlayGameAction;
import net.rezmason.scourge.waves.WaveDemo;
import net.rezmason.utils.santa.Present;

class GamePage extends NavPage {

    var bodiesByName:Map<String, Body>;
    // var console:UIElement;
    // var consoleMed:ConsoleUIMediator;
    var currentBodyName:String;
    var sceneGraph:SceneGraph;

    public function new():Void {
        super();

        // consoleMed = new ConsoleUIMediator();
        // var interpreter = new Interpreter(consoleMed, [GRAVE]);
        // console = new UIElement(consoleMed);

        var alphabetDemo:AlphabetDemo = new AlphabetDemo();
        var sdfFontDemo:SDFFontDemo = new SDFFontDemo();
        var colorSolidDemo:ColorSolidDemo = new ColorSolidDemo();
        var matrixDemo:MatrixDemo = new MatrixDemo();
        var waveDemo:WaveDemo = new WaveDemo();
        var view:View = new Present(View);

        sceneGraph = new Present(SceneGraph);
        sceneGraph.toggleConsoleSignal.add(toggleConsole);

        bodiesByName = new Map();
        bodiesByName['alphabet']   = alphabetDemo.body;
        bodiesByName['sdf']        = sdfFontDemo.body;
        bodiesByName['colorSolid'] = colorSolidDemo.body;
        bodiesByName['matrix']     = matrixDemo.body;
        bodiesByName['waves']      = waveDemo.body;
        bodiesByName['board']      = view.body;

        // console.hasScrollBar = true;
        // console.setLayout(0.25, 0.25, 0.5, 0.5);
        // console.body.visible = false;
        // scenes.push(console.scene);

        /*
        interpreter.addAction(new SetLayoutAction(console));
        interpreter.addAction(new SetNameAction(interpreter));
        interpreter.addAction(new PrintAction());
        interpreter.addAction(new PlayGameAction(showBodyByName.bind('board')));
        interpreter.addAction(new SetWindowSizeAction());
        
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
        */

        showBodyByName('colorSolid');
    }

    function toggleConsole() {
        // console.body.visible = !console.body.visible;
        // if (console.body.visible) sceneGraph.setKeyboardFocus(console.body);
        // else sceneGraph.setKeyboardFocus(null);
    }

    function showBodyByName(name:String):Void {
        if (currentBodyName != null) body.removeChild(bodiesByName[currentBodyName]);
        currentBodyName = name;
        body.addChild(bodiesByName[currentBodyName]);
        sceneGraph.invalidate();
    }
}
