package net.rezmason.scourge.textview;

import openfl.Assets;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.console.ConsoleUIMediator;

import net.rezmason.utils.FlatFont;

class TextDemo {

    var engine:Engine;
    var stage:Stage;
    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;

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
        var console = new ConsoleUIMediator();
        var uiBody = new UIBody(utils.bufferUtil, fontTextures['full'], new ConsoleUIMediator());
        var rect:Rectangle = new Rectangle(0, 0, 1, 1);
        rect.inflate(-0.02, -0.02);
        uiBody.viewRect = rect;
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
}
