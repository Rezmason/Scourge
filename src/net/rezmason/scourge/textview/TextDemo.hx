package net.rezmason.scourge.textview;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.utils.FlatFont;

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

    public function new(utils:UtilitySet, stage:Stage, fonts:Map<String, FlatFont>):Void {
        this.utils = utils;
        this.stage = stage;
        makeFontTextures(fonts);
        engine = new Engine(utils, stage, fontTextures);
        engine.init(makeScene);
        addListeners();
    }

    function makeFontTextures(fonts:Map<String, FlatFont>):Void {
        fontTextures = new Map();
        for (key in fonts.keys()) fontTextures[key] = new GlyphTexture(utils.textureUtil, fonts[key]);
    }

    function makeScene():Void {

        //*
        testBody = new TestBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        testBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(testBody);
        /**/

        /*
        var game:Game = null;
        boardBody = new BoardBody(utils.bufferUtil, fontTextures['full'], engine.invalidateMouse, game);
        boardBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(boardBody);
        /**/

        //*
        interpreter = new Interpreter();
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

    function onResize(?event:Event):Void engine.setSize(stage.stageWidth, stage.stageHeight);
    function onActivate(?event:Event):Void engine.activate();
    function onDeactivate(?event:Event):Void engine.deactivate();

    // function onMouseViewClick(?event:Event):Void mouseSystem.invalidate();
}
