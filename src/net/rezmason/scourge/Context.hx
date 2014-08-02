package net.rezmason.scourge;

import openfl.Assets.*;

import flash.display.Stage;
import flash.events.Event;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.NavSystem;
import net.rezmason.scourge.textview.ScourgeNavPageAddresses;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.pages.*;
import net.rezmason.utils.display.FlatFont;

class Context {

    var engine:Engine;
    var stage:Stage;
    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;
    var navSystem:NavSystem;

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
        for (name in ['full']) {
            var path:String = 'flatfonts/${name}_flat';
            var font:FlatFont = new FlatFont(getBitmapData('$path.png'), getText('$path.json'));
            fontTextures[name] = cast new GlyphTexture(utils.textureUtil, font);
        }
    }

    function init():Void {
        addListeners();
        var fullTexture:GlyphTexture = fontTextures['full'];
        
        navSystem = new NavSystem(engine);
        navSystem.addPage(ScourgeNavPageAddresses.SPLASH, new SplashPage(utils.bufferUtil, fullTexture));
        navSystem.addPage(ScourgeNavPageAddresses.ABOUT, new AboutPage(utils.bufferUtil, fullTexture));
        navSystem.addPage(ScourgeNavPageAddresses.GAME, new GamePage(utils.bufferUtil, fullTexture));

        navSystem.goto(Page(ScourgeNavPageAddresses.SPLASH));
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
