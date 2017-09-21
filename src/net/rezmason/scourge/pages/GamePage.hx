package net.rezmason.scourge.pages;

import net.rezmason.hypertype.console.*;
import net.rezmason.hypertype.core.Container;
import net.rezmason.hypertype.core.Stage;
import net.rezmason.hypertype.demo.*;
import net.rezmason.hypertype.nav.NavPage;
import net.rezmason.hypertype.useractions.*;
import net.rezmason.scourge.View;
import net.rezmason.scourge.useractions.PlayGameAction;
import net.rezmason.scourge.waves.WaveDemo;
import net.rezmason.utils.santa.Present;

class GamePage extends NavPage {

    var containersByName:Map<String, Container>;
    // var console:UIElement;
    // var consoleMed:ConsoleUIMediator;
    var currentBodyName:String;
    var stage:Stage;

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

        stage = new Present(Stage);
        stage.toggleConsoleSignal.add(toggleConsole);

        containersByName = new Map();
        containersByName['alphabet']   = alphabetDemo.container;
        containersByName['sdf']        = sdfFontDemo.container;
        containersByName['colorSolid'] = colorSolidDemo.container;
        containersByName['matrix']     = matrixDemo.container;
        containersByName['waves']      = waveDemo.container;
        containersByName['board']      = view.container;

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
            if (containersByName[bodyName] != null) {
                showBodyByName(bodyName);
                message = 'Showing $bodyName.';
            } else {
                message = ConsoleUtils.styleError('"$bodyName" not found.');
            }
            outputSignal.dispatch(message, true);
        }));
        */

        container.boundingBox.scaleMode = SHOW_ALL;
        showBodyByName('colorSolid');
    }

    function toggleConsole() {
        // console.body.visible = !console.body.visible;
        // if (console.body.visible) stage.setKeyboardFocus(console.body);
        // else stage.setKeyboardFocus(null);
    }

    function showBodyByName(name:String):Void {
        if (currentBodyName != null) container.removeChild(containersByName[currentBodyName]);
        currentBodyName = name;
        container.addChild(containersByName[currentBodyName]);
    }
}
