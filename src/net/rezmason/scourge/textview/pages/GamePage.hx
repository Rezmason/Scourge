package net.rezmason.scourge.textview.pages;

import flash.geom.Rectangle;

import net.rezmason.scourge.textview.board.BoardBody;
import net.rezmason.scourge.textview.commands.*;
import net.rezmason.scourge.textview.console.*;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Scene;
import net.rezmason.scourge.textview.demo.*;
import net.rezmason.scourge.textview.ui.UIBody;
import net.rezmason.utils.Zig;

class GamePage extends NavPage {

    var gameSystem:GameSystem;
    var bodiesByName:Map<String, Body>;
    var currentBodyName:String;
    var console:ConsoleUIMediator;
    var mainScene:Scene;
    var sideScene:Scene;

    public function new():Void {
        super();

        mainScene = new Scene();
        sideScene = new Scene();
        scenes.push(mainScene);
        scenes.push(sideScene);

        console = new ConsoleUIMediator();
        var interpreter = new Interpreter(console);
        var boardBody:BoardBody  = new BoardBody();
        var uiBody:UIBody = new UIBody(console);

        bodiesByName = new Map();
        bodiesByName['alphabet'] = new AlphabetBody();
        bodiesByName['sdf']      = new GlyphBody();
        bodiesByName['test']     = new TestBody();
        bodiesByName['board']    = boardBody;

        for (key in bodiesByName.keys()) {
            bodiesByName[key].camera.rect = new Rectangle(0, 0, 0.6, 1);
        }

        uiBody.camera.rect = new Rectangle(0.6, 0, 0.4, 1);
        uiBody.showScrollBar = true;
        sideScene.addBody(uiBody);
        gameSystem = new GameSystem(boardBody, console); // Doesn't really belong in here

        interpreter.addCommand(new RunTestsConsoleCommand());
        interpreter.addCommand(new SetFontConsoleCommand(uiBody));
        interpreter.addCommand(new SetNameConsoleCommand(interpreter));
        interpreter.addCommand(new PrintConsoleCommand());
        interpreter.addCommand(new SimpleCommand('clear', clearConsoleCommand));
        interpreter.addCommand(new SimpleCommand('show', showBodyCommand));
        interpreter.addCommand(new PlayGameConsoleCommand(showBodyByName.bind('board'), gameSystem));

        showBodyByName('board');
    }

    function clearConsoleCommand(args, outputSignal):Void {
        console.clearText();
        outputSignal.dispatch(null, true);
    }

    function showBodyCommand(args, outputSignal):Void {
        var bodyName:String = args.tail;
        var message:String = null;
        if (bodiesByName[bodyName] != null) {
            showBodyByName(bodyName);
            message = 'Showing $bodyName.';
        } else {
            message = ConsoleUtils.styleError('"$bodyName" not found.');
        }
        outputSignal.dispatch(message, true);
    }

    function hasBodyByName(name:String):Bool return bodiesByName[name] != null;

    function showBodyByName(name:String):Void {
        if (currentBodyName != null) mainScene.removeBody(bodiesByName[currentBodyName]);
        currentBodyName = name;
        mainScene.addBody(bodiesByName[currentBodyName]);
        mainScene.focus = bodiesByName[currentBodyName];
        updateViewSignal.dispatch();
    }
}
