package net.rezmason.scourge.textview.pages;

import flash.geom.Rectangle;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.console.*;
import net.rezmason.scourge.textview.commands.*;
import net.rezmason.scourge.textview.demo.*;
import net.rezmason.scourge.textview.ui.UIBody;
import net.rezmason.scourge.textview.board.BoardBody;
import net.rezmason.gl.utils.BufferUtil;

class GamePage extends NavPage {

    var gameSystem:GameSystem;
    var bodiesByName:Map<String, Body>;
    var currentBodyName:String;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {
        super();

        var console = new ConsoleUIMediator();
        var interpreter = new Interpreter(console);

        bodiesByName = new Map();
        bodiesByName['alphabet'] = new AlphabetBody(bufferUtil, glyphTexture);
        bodiesByName['sdf']      = new GlyphBody(bufferUtil, glyphTexture);
        bodiesByName['test']     = new TestBody(bufferUtil, glyphTexture);
        var boardBody:BoardBody  = new BoardBody(bufferUtil, glyphTexture);
        bodiesByName['board']    = boardBody;

        for (key in bodiesByName.keys()) {
            bodiesByName[key].viewRect = new Rectangle(0, 0, 0.6, 1);
        }

        var uiBody:UIBody = new UIBody(bufferUtil, glyphTexture, console);
        uiBody.viewRect = new Rectangle(0.6, 0, 0.4, 1);
        bodies.push(uiBody);

        gameSystem = new GameSystem(boardBody, console); // Doesn't really belong in here

        interpreter.addCommand(new RunTestsConsoleCommand());
        interpreter.addCommand(new SetFontConsoleCommand(uiBody));
        interpreter.addCommand(new SetNameConsoleCommand(interpreter));
        interpreter.addCommand(new PrintConsoleCommand());
        interpreter.addCommand(new ClearConsoleCommand(console)); // Wrapper
        interpreter.addCommand(new ShowBodyConsoleCommand(hasBodyByName, showBodyByName)); // Wrapper
        interpreter.addCommand(new PlayGameConsoleCommand(showBodyByName, gameSystem)); // Wrapper

        showBodyByName('board');
    }

    function hasBodyByName(name:String):Bool return bodiesByName[name] != null;

    function showBodyByName(name:String):Void {
        if (currentBodyName != null && currentBodyName != name) bodies.remove(bodiesByName[currentBodyName]);
        currentBodyName = name;
        bodies.push(bodiesByName[currentBodyName]);
        updateViewSignal.dispatch();
    }
}
