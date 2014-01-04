package net.rezmason.scourge.textview;

import openfl.Assets;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import massive.munit.TestRunner;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.controller.RandomSmarts;
import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.ReplaySmarts;
import net.rezmason.scourge.controller.SimpleSpectator;
import net.rezmason.scourge.controller.Types;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.console.ConsoleText;
import net.rezmason.scourge.textview.console.Interpreter;
import net.rezmason.scourge.textview.console.TextCommand;

import net.rezmason.utils.FlatFont;

using Lambda;

class TextDemo {

    var engine:Engine;

    var stage:Stage;

    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;
    var bodiesByName:Map<String, Body>;
    var boardBody:BoardBody;
    var uiBody:UIBody;

    var referee:Referee;
    var spectator:SimpleSpectator;
    var turnFuncs:Array<Void->Void>;

    var console:ConsoleText;
    var interpreter:Interpreter;

    var currentBody:Body;
    var currentBodyViewRect:Rectangle;

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        makeFontTextures(fonts);
        engine = new Engine(utils, stage, fontTextures);
        engine.readySignal.add(init);
        engine.init();
    }

    function makeFontTextures(fonts:Map<String, FlatFont>):Void {
        fontTextures = new Map();
        for (key in fonts.keys()) {
            fontTextures[key] = cast new GlyphTexture(utils.textureUtil, fonts[key]);
            fontTextures[key + "_fog"] = cast new GlyphTexture(utils.textureUtil, fonts[key]);
        }
    }

    function init():Void {
        addListeners();
        makeInterpreter();
        makeBodies();
    }

    function makeGame(input:String):String {

        if (referee == null) referee = new Referee();
        else if (referee.gameBegun) referee.endGame();

        if (spectator == null) spectator = new SimpleSpectator();
        spectator.viewSignal.removeAll();

        var args:Array<String> = input.split(' ');
        args.shift();

        var numPlayers:Int = Std.parseInt(args.shift());
        if (numPlayers > 8) numPlayers = 8;
        if (numPlayers < 2) numPlayers = 2;

        var botPeriod:Int = Std.parseInt(args.shift());

        var circular:Bool = args.has('-circular');

        var cfg:ScourgeConfig = ScourgeConfigFactory.makeDefaultConfig();
        cfg.pieceTableIDs = cfg.pieces.getAllPieceIDsOfSize(4);
        cfg.allowRotating = true;
        cfg.circular = circular;
        cfg.allowNowhereDrop = false;
        cfg.numPlayers = numPlayers;
        cfg.includeCavities = true;

        cfg.maxSwaps = 0;
        cfg.maxBites = 0;

        var playerDefs:Array<PlayerDef> = [];
        var randFunc:Void->Float = randomFunction;

        if (args.has('replay')) {
            if (referee.lastGame == null) return 'Referee has no replay.';
            cfg = referee.lastGameConfig;
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
            spectator.viewSignal.add(boardBody.invalidateBoard);
        }

        setCurrentBody(boardBody);

        return 'Starting a $numPlayers player game.';
    }

    function playerActionsOnly(event:GameEvent):Bool {
        var isPlayerAction:Bool = false;
        switch (event.type) {
            case PlayerAction(SubmitMove(action, move)): isPlayerAction = true;
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

    function setFontSize(input:String):String {
        var size:Float = Std.parseFloat(input.split(' ')[1]);
        if (!uiBody.setFontSize(size)) {
            return '$size is an invalid font size.';
        }
        return 'Font size set to $size.';
    }

    function setName(input:String):String {
        var args:Array<String> = input.split(' ');
        var name:String = args[1];
        var color:Int = 0xFFFFFF;
        if (args[2] != null) color = Std.parseInt(args[2]);
        console.setPlayer(name, color);
        return 'Done.';
    }

    function print(input:String):String {
        var strName:String = input.substr(input.indexOf(' ') + 1);
        var str:String = Assets.getText('exampletext/$strName.txt');
        if (str == null) str = 'String $strName not found.';
        return str;
    }

    function show(input:String):String {
        var bodyName:String = input.substr(input.indexOf(' ') + 1);
        var body:Body = bodiesByName[bodyName.toLowerCase()];
        var str:String = null;
        if (body == null) str = '"$bodyName" not found.';
        else str = 'Showing "$bodyName"';

        if (body != null) setCurrentBody(body);

        return str;
    }

    function makeInterpreter():Void {
        console = new ConsoleText();
        interpreter = new Interpreter();
        interpreter.connectToConsole(console);

        interpreter.addCommand('runTests', new TextCommand(runTests));
        interpreter.addCommand('setFont', new TextCommand(setFont));
        interpreter.addCommand('setFontSize', new TextCommand(setFontSize));
        interpreter.addCommand('setName', new TextCommand(setName));
        interpreter.addCommand('makeGame', new TextCommand(makeGame));
        interpreter.addCommand('print', new TextCommand(print));
        interpreter.addCommand('show', new TextCommand(show));
    }

    function makeBodies():Void {
        currentBodyViewRect = new Rectangle(0, 0, 0.6, 1);
        bodiesByName = new Map();

        boardBody = new BoardBody(utils.bufferUtil, fontTextures['full_fog']);
        bodiesByName['board'] = cast boardBody;

        var splashBody = new SplashBody(utils.bufferUtil, fontTextures['full']);
        splashBody.viewRect = new Rectangle(0, 0, 1, 0.3);
        bodiesByName['splash'] = cast splashBody;

        bodiesByName['alphabet'] = cast new AlphabetBody(utils.bufferUtil, fontTextures['full']);
        bodiesByName['sdf'] = cast new GlyphBody(utils.bufferUtil, fontTextures['full']);
        bodiesByName['test'] = cast new TestBody(utils.bufferUtil, fontTextures['full']);
        // #if flash bodiesByName['video'] = new VideoBody(utils.bufferUtil, fontTextures['full']); #end

        uiBody = new UIBody(utils.bufferUtil, fontTextures['full'], console);
        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1); // 0.6, 0, 0.4, 1
        uiRect.inflate(-0.0125, -0.0125);
        uiBody.viewRect = uiRect;
        engine.addBody(uiBody);
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

    function runTests(input:String):String {
        var client = new SimpleTestClient();
        var runner:TestRunner = new TestRunner(client);
        runner.completionHandler = function(b) {};
        runner.run([TestSuite]);
        return client.output;
    }

    function setCurrentBody(body:Body):Void {
        if (currentBody != body) {
            if (currentBody != null) engine.removeBody(currentBody);
            currentBody = body;
            if (currentBody != null) {
                currentBody.viewRect = currentBodyViewRect;
                engine.addBody(currentBody);
            }
        }
    }

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();
}
