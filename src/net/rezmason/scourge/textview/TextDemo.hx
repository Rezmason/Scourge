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

import haxe.Timer;

using Lambda;

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

    var robotTimer:Timer;

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        makeFontTextures(fonts);
        engine = new Engine(utils, stage, fontTextures);
        engine.init(init);
        addListeners();
        robotTimer = null;
    }

    function makeFontTextures(fonts:Map<String, FlatFont>):Void {
        fontTextures = new Map();
        for (key in fonts.keys()) {
            fontTextures[key] = cast new GlyphTexture(utils.textureUtil, fonts[key]);
            fontTextures[key + "_fog"] = cast new FoggyGlyphTexture(utils.textureUtil, fonts[key]);
        }
    }

    function init():Void {
        makeScene();
    }

    function takeTurn(game:Game, func:Void->Void):Void {
        if (this.game == null) {
            this.game = game;
            turnFuncs = [];

            if (boardBody != null) {
                boardBody.attach(this.game, referee.numPlayers);
                onResize();
            }
        }

        turnFuncs.push(func);
    }

    function makeTurn():Void {

        var funcs:Array<Void->Void> = turnFuncs.splice(0, turnFuncs.length);
        funcs.reverse();

        if (funcs.length > 0) {
            while (funcs.length > 0) funcs.pop()();
            boardBody.handleBoardUpdate();
        }
    }

    function makeTurn2():Void {
        makeTurn();
        makeTurn();
    }

    function startRobots(input:String):String {
        stopRobots("");
        robotTimer = new Timer(Std.parseInt(input.split(' ')[1]));
        trace(input);
        robotTimer.run = makeTurn2;
        makeTurn2();
        return "ROBOTS STARTED";
    }

    function stopRobots(input:String):String {
        if (robotTimer != null) robotTimer.stop();
        robotTimer = null;
        return "ROBOTS STOPPED";
    }

    function makeGame(input:String):String {

        stopRobots("");

        if (referee == null) referee = new Referee();
        else referee.endGame();

        game = null;

        var args:Array<String> = input.split(' ');

        var numPlayers:Int = Std.parseInt(args[1]);

        if (numPlayers < 2) numPlayers = 2;

        var playerCfgs = [];

        for (ike in 0...numPlayers) playerCfgs.push({type:Test(takeTurn, false)});

        var cfg = ScourgeConfigFactory.makeDefaultConfig();
        cfg.allowRotating = false;
        cfg.circular = args.has('circular');
        cfg.allowAllPieces = false;
        cfg.numPlayers = playerCfgs.length;
        referee.beginGame(playerCfgs, randomFunction, cfg);

        return 'Starting a $numPlayers player game.';
    }

    function randomFunction():Float {
        return 0;
    }

    function setFont(input:String):String {
        var fontName:String = input.split(' ')[1];
        var fontTexture:GlyphTexture = fontTextures[fontName];
        if (fontTexture == null) return 'Font $fontName does not exist.';
        for (body in engine.eachBody()) body.glyphTexture = fontTexture;
        return 'Font set to $fontName';
    }

    function makeScene():Void {

        /*
        testBody = new TestBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        testBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(testBody);
        /**/

        //*
        boardBody = new BoardBody(utils.bufferUtil, fontTextures['full_fog'], engine.invalidateMouse);
        boardBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(boardBody);
        /**/

        //*
        interpreter = new Interpreter();
        interpreter.addCommand("startRobots", startRobots);
        interpreter.addCommand("stopRobots", stopRobots);
        interpreter.addCommand("runTests", runTests);
        interpreter.addCommand("setFont", setFont);
        interpreter.addCommand("makeGame", makeGame);
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
        onActivate();
    }

    function addListeners():Void {
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);
        stage.addEventListener(Event.RESIZE, onResize);
    }

    function onResize(?event:Event):Void {
        engine.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        engine.activate();
        if (uiBody != null) engine.setKeyboardFocus(uiBody);
    }

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
