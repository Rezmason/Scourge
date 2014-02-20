package net.rezmason.scourge;

import openfl.Assets.*;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.*;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.console.*;
import net.rezmason.scourge.textview.commands.*;
import net.rezmason.scourge.textview.demo.*;
import net.rezmason.scourge.textview.ui.UIBody;

import net.rezmason.scourge.textview.board.BoardBody;
import net.rezmason.scourge.textview.ui.SplashBody;

import net.rezmason.utils.display.FlatFont;

class Context {

    var engine:Engine;
    var stage:Stage;
    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;
    var displaySystem:DisplaySystem;
    var gameSystem:GameSystem;

    public function new(utils:UtilitySet, stage:Stage):Void {
        this.utils = utils;
        this.stage = stage;
        makeFontTextures();
        engine = new Engine(utils, stage, fontTextures);
        engine.readySignal.add(init);
        engine.init();
    }

    function makeFontTextures():Void {
        fontTextures = new Map();
        for (name in ['source', 'profont', 'full']) {
            var path:String = 'flatfonts/${name}_flat';
            var font:FlatFont = new FlatFont(getBitmapData('$path.png'), getText('$path.json'));
            fontTextures[name] = cast new GlyphTexture(utils.textureUtil, font);
        }
    }

    function init():Void {
        addListeners();
        displaySystem = new DisplaySystem(engine);
        var console = new ConsoleUIMediator();
        var interpreter = new Interpreter(console);
        var fullTexture:GlyphTexture = fontTextures['full'];

        var regions:Map<String, Rectangle> = [
            'full'      => new Rectangle(0.0, 0.0, 1.0, 1.0),
            'main'      => new Rectangle(0.0, 0.0, 0.6, 1.0),
            'console'   => new Rectangle(0.6, 0.0, 0.4, 1.0),
            'splash'    => new Rectangle(0.0, 0.0, 1.0, 0.3),
            'splashnav' => new Rectangle(0.0, 0.7, 1.0, 0.3),
        ];
        for (regionName in regions.keys()) displaySystem.addRegion(regionName, regions[regionName]);

        var bodies:Map<String, Class<Body>> = [
            'splash'    => SplashBody,
            'alphabet'  => AlphabetBody,
            'sdf'       => GlyphBody,
            'test'      => TestBody,
            // #if flash 'video'     => VideoBody, #end
        ];
        for (bodyName in bodies.keys()) {
            var body:Body = Type.createInstance(bodies[bodyName], [utils.bufferUtil, fullTexture]);
            displaySystem.addBody(bodyName, body);
        }

        var uiBody:UIBody = new UIBody(utils.bufferUtil, fullTexture, console);
        displaySystem.addBody('console', uiBody, 'console');

        var boardBody:BoardBody = new BoardBody(utils.bufferUtil, fullTexture);
        displaySystem.addBody('board', boardBody);

        gameSystem = new GameSystem(boardBody);

        interpreter.addCommand(new RunTestsConsoleCommand());
        interpreter.addCommand(new SetFontConsoleCommand(uiBody, fontTextures));
        interpreter.addCommand(new SetNameConsoleCommand(interpreter));
        interpreter.addCommand(new PrintConsoleCommand());
        interpreter.addCommand(new ClearConsoleCommand(console));
        interpreter.addCommand(new ShowBodyConsoleCommand(displaySystem));
        #if (neko || cpp)
            interpreter.addCommand(new QuitConsoleCommand());
        #end
        interpreter.addCommand(new PlayGameConsoleCommand(displaySystem, gameSystem));
    }

    function addListeners():Void {
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.RESIZE, onResize);

        // these kind of already happened, so we just trigger them
        onResize();
        onActivate();
    }

    function onResize(?event:Event):Void engine.setSize(stage.stageWidth, stage.stageHeight);
    function onActivate(?event:Event):Void engine.activate();
    function onDeactivate(?event:Event):Void engine.deactivate();
}
