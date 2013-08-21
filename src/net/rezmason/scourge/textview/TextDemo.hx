package net.rezmason.scourge.textview;

import flash.display.Stage;
import flash.events.Event;
import flash.geom.Rectangle;

import net.rezmason.ropes.Types.Move;
import net.rezmason.scourge.controller.Operation;

import net.rezmason.gl.utils.UtilitySet;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.utils.FlatFont;

using Lambda;

class TextDemo {

    var engine:Engine;

    var stage:Stage;

    var utils:UtilitySet;
    var fontTextures:Map<String, GlyphTexture>;
    var splashBody:Body;
    var testBody:TestBody;
    var uiBody:UIBody;

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

        var _id:Int = 0;

        //*
        testBody = new TestBody(_id++, utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        testBody.viewRect = new Rectangle(0, 0, 0.6, 1);
        engine.addBody(testBody);
        /**/

        //*
        uiBody = new UIBody(_id++, utils.bufferUtil, fontTextures['full'], engine.invalidateMouse, new UIText(interpretCommand));
        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);
        // uiRect = new Rectangle(0, 0, 1, 1);
        uiBody.viewRect = uiRect;
        engine.addBody(uiBody);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(_id++, utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
        engine.addBody(alphabetBody);
        /**/

        /*
        splashBody = new SplashBody(_id++, utils.bufferUtil, fontTextures['full'], engine.invalidateMouse);
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

    function interpretCommand(input:String, hinting:Bool):Command {

        var allMoves:Array<Array<Move>> = [[],[],[],[]];
        var operations:Map<String, Operation> = [
            'bite' => new Operation(0, new Map()),
            'drop' => new Operation(1, new Map()),
            'swap' => new Operation(2, new Map()),
            'skip' => new Operation(3, new Map()),
        ];

        // input string is free of syles and hint data

        if (input == null || input.length == 0) return EMPTY;

        var opName:String = input;
        var spcIndex:Int = input.indexOf(' ');
        if (spcIndex != -1) opName = input.substr(0, spcIndex);

        if (opName == 'msg') {
            //     style the opName as a opName
            //     style
            return CHAT(input.substr(opName.length + 1));
        }

        var op:Operation = operations[opName];
        if (op == null) {
            //     style the opName as invalid
            //     style the rest as dim invalid
            return ERROR('UNRECOGNIZED COMMAND $opName');
        }

        // style the opName as a opName

        var stack:Array<String> = input.split(' ');
        stack.reverse();
        stack.pop();

        var filteredMoves = allMoves[op.index].copy();

        var keys:Array<String> = [];

        while (stack.length > 0) {
            var key:String = stack.pop();
            var value:String = stack.pop();

            if (!op.hasParam(key)) {
                //    style key as invalid
                //    style the rest as dim invalid
                return ERROR('UNRECOGNIZED PARAM $key');
            }

            filteredMoves = op.applyFilter(key, value, filteredMoves);

            if (filteredMoves == null) {
                //    style value as invalid
                //    style the rest as dim invalid
                return ERROR('INVALID VALUE $value FOR PARAM $key');
            }

            keys.push(key);

            //    style key as a param
            //    style value as a value
        }

        if (hinting) {
            var hint:String = '';
            for (paramName in op.params) {
                if (!keys.has(paramName)) {
                    //     style as a "hint button"
                    hint += ' $paramName';
                }
            }
        } else {
            if (filteredMoves.length == 1) return COMMIT('MOVE: ${filteredMoves[0]}');
            else return LIST(filteredMoves.map(printMove));
        }

        return null;
    }

    function printMove(move:Move):String {
        var str:String = '';
        for (field in Reflect.fields(move)) str += '$field : ${Reflect.field(move, field)},';
        return '[$str]';
    }
}
