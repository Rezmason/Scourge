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

import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.controller.SimpleSpectator;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

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

    var referee:Referee;
    var spectator:SimpleSpectator;
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
        for (key in fonts.keys()) {
            fontTextures[key] = cast new GlyphTexture(utils.textureUtil, fonts[key]);
            fontTextures[key + "_fog"] = cast new GlyphTexture(utils.textureUtil, fonts[key]);
        }
    }

    function init():Void {
        makeScene();
    }

    function makeGame(input:String):String {

        if (referee == null) referee = new Referee();
        else if (referee.gameBegun) referee.endGame();

        if (spectator == null) spectator = new SimpleSpectator();
        spectator.viewSignal.removeAll();

        var args:Array<String> = input.split(' ');

        var circular:Bool = args.has('circular');

        var numPlayers:Int = Std.parseInt(args[1]);
        if (numPlayers > 8) numPlayers = 8;
        if (numPlayers < 2) numPlayers = 2;

        var cfg:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        cfg.pieceTableIDs = cfg.pieces.getAllPieceIDsOfSize(4);
        cfg.allowRotating = true;
        cfg.circular = circular;
        cfg.allowNowhereDrop = false;
        cfg.numPlayers = numPlayers;
        cfg.includeCavities = true;
        // cfg.maxSwaps = 0;
        // cfg.maxBites = 0;

        var playerDefs:Array<PlayerDef> = [];
        var botPeriod:Int = 10;
        var randFunc:Void->Float = randomFunction;

        if (args.has('replay')) {
            if (referee.lastGame == null) return 'Referee has no replay.';
            cfg = referee.lastGame.config;
            numPlayers = cfg.numPlayers;
            circular = cfg.circular;
            var log:Array<GameEvent> = referee.lastGame.log.filter(playerActionsOnly);
            var floats:Array<Float> = referee.lastGame.floats.copy();
            randFunc = function() return floats.shift();

            while (playerDefs.length < numPlayers) playerDefs.push(Bot(new ReplaySmarts(log), botPeriod));
        } else {
            while (playerDefs.length < numPlayers) playerDefs.push(Bot(new RandomSmarts(), botPeriod));
        }

        var spectators:Array<SimpleSpectator> = [spectator];

        referee.beginGame(playerDefs, cast spectators, randFunc, cfg);

        if (boardBody != null) {
            boardBody.attach(spectator.getGame(), referee.numPlayers);
            onResize();
            spectator.viewSignal.add(boardBody.handleBoardUpdate);
        }

        return 'Starting a $numPlayers player game.';
    }

    function playerActionsOnly(event:GameEvent):Bool {
        var isPlayerAction:Bool = false;
        switch (event.type) {
            case PlayerAction(action, move): isPlayerAction = true;
            case _:
        }
        return isPlayerAction;
    }

    function randomFunction():Float {
        return Math.random();
        // return 0;
    }

    function setFont(input:String):String {
        var fontName:String = input.split(' ')[1];
        var fontTexture:GlyphTexture = fontTextures[fontName];
        if (fontTexture == null) return 'Font $fontName does not exist.';
        for (body in engine.eachBody()) body.glyphTexture = fontTexture;
        return 'Font set to $fontName';
    }

    function makeScene():Void {

        //*
        testBody = new TestBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        testBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(testBody);
        /**/

        /*
        boardBody = new BoardBody(utils.bufferUtil, fontTextures['full_fog'], engine.invalidateMouse);
        boardBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(boardBody);
        /**/

        //*
        // interpreter = new Interpreter();
        // interpreter.addCommand("runTests", runTests);
        // interpreter.addCommand("setFont", setFont);
        // interpreter.addCommand("makeGame", makeGame);
        var uiText:UIText = new UIText();
        // TODO: signal handling
        uiBody = new UIBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse, uiText);
        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiBody.viewRect = uiRect;
        uiBody.padding = 0.025;
        engine.addBody(uiBody);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        engine.addBody(alphabetBody);
        /**/

        /*
        var glyphBody:Body = new GlyphBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        glyphBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(glyphBody);
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

    function onResize(?event:Event):Void engine.setSize(stage.stageWidth, stage.stageHeight);

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
