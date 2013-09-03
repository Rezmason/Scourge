package net.rezmason.scourge.textview;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import massive.munit.TestRunner;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.utils.FlatFont;

import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfigFactory;

class TextDemo {

    var engine:Engine;

    var stage:Stage;

    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;
    var splashBody:Body;
    var testBody:TestBody;
    var boardBody:BoardBody;
    var uiBody:UIBody;
    var interpreter:Interpreter;

    var game:Game;
    var referee:Referee;
    var turnFuncs:Array<Void->Void>;

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        makeFontTextures(fonts);
        engine = new Engine(utils, stage, fontTextures);
        engine.init(init);
        addListeners();
    }

    function makeFontTextures(fonts:Map<String, FlatFont>):Void {
        fontTextures = new Map();
        for (key in fonts.keys()) fontTextures[key] = new GlyphTexture(utils.textureUtil, fonts[key]);
    }

    function init():Void {
        makeGame();
    }

    function takeTurn(game:Game, func:Void->Void):Void {
        if (this.game == null) {
            this.game = game;
            makeScene();
            turnFuncs = [];
        }
        turnFuncs.push(func);
    }

    function makeTurn(input:String):String {

        var output:String = "PROBLEM?";

        var funcs:Array<Void->Void> = turnFuncs.splice(0, turnFuncs.length);
        funcs.reverse();

        if (funcs.length > 0) {
            while (funcs.length > 0) funcs.pop()();
            boardBody.handleBoardUpdate();
            output = "MOVED";
        }

        return output;
    }

    function makeGame():Void {
        var playerCfgs = [
            {type:Test(takeTurn, false)},
            {type:Test(takeTurn, false)},
        ];
        var cfg = ScourgeConfigFactory.makeDefaultConfig();
        // cfg.circular = true;
        cfg.numPlayers = playerCfgs.length;
        referee = new Referee();
        referee.beginGame(playerCfgs, randomFunction, cfg);
    }

    function randomFunction():Float {
        return 0;
    }

    function makeScene():Void {

        /*
        testBody = new TestBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        testBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(testBody);
        /**/

        //*
        boardBody = new BoardBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse, game);
        boardBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(boardBody);
        /**/

        //*
        interpreter = new Interpreter();
        interpreter.addCommand("makeTurn", makeTurn);
        interpreter.addCommand("runTests", runTests);
        uiBody = new UIBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse, new UIText(interpreter));
        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);
        // uiRect = new Rectangle(0, 0, 1, 1);
        uiBody.viewRect = uiRect;
        engine.addBody(uiBody);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        engine.addBody(alphabetBody);
        /**/

        /*
        splashBody = new SplashBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        engine.addBody(splashBody);
        /**/

        onResize();
        engine.activate();
    }

    function addListeners():Void {
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.RESIZE, onResize);
    }

    function onResize(?event:Event):Void {
        engine.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void engine.activate();
    function onDeactivate(?event:Event):Void engine.deactivate();

    function runTests(input:String):String {
        var client = new SimpleTestClient();
        var runner:TestRunner = new TestRunner(client);
        runner.completionHandler = function(b) trace(client.output);
        runner.run([TestSuite]);
        return "Running tests";
    }

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();
}
