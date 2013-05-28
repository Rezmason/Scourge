package net.rezmason.scourge.textview;

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.utils.Timer;
import net.rezmason.scourge.textview.core.*;
// import net.rezmason.scourge.textview.rendermethods.*;
// import net.rezmason.scourge.textview.utils.UtilitySet;
import net.rezmason.utils.FlatFont;

import openfl.display.OpenGLView;
import openfl.gl.GL;
import openfl.gl.GLBuffer;
import openfl.gl.GLProgram;
import openfl.gl.GLShader;
import openfl.gl.GLUniformLocation;
import openfl.utils.Float32Array;

using net.rezmason.scourge.textview.core.GlyphUtils;

typedef HaxeTimer = haxe.Timer;
// typedef View = {rect:Rectangle, body:Body};

class WebGLFuckBox {

    var active:Bool;
    var stage:Stage;
    var rect:Rectangle;

    var updateTimer:Timer;
    var lastTimeStamp:Float;

    var text:String;

    var fonts:Map<String, FlatFont>;
    var shaderProgram:GLProgram;
    var vertexAttribute:Int;
    var vertexBuffer:GLBuffer;
    var view:OpenGLView;

    // var utils:UtilitySet;
    // var bodies:Array<Body>;
    // var views:Array<View>;
    // var fontTextures:Map<String, GlyphTexture>;

    // var mouseSystem:MouseSystem;
    // var mouseMethod:RenderMethod;
    // var prettyMethod:RenderMethod;
    // var renderer:Renderer;

    // var splashBody:Body;
    // var testBody:TestBody;
    // var uiBody:UIBody;

    public function new(stage:Stage, fonts:Map<String, FlatFont>, text:String):Void {
        active = false;
        this.stage = stage;
        this.fonts = fonts;
        this.text = text;

        //utils = new UtilitySet(stage, onCreate);
        onCreate(); // !
    }

    function onCreate():Void {
        makeFontTextures();
        // mouseSystem = new MouseSystem(stage, interact);
        // stage.addChild(mouseSystem.view);
        // renderer = new Renderer(utils.drawUtil, mouseSystem);
        // prettyMethod = new PrettyMethod(utils.programUtil);
        // mouseMethod = new MouseMethod(utils.programUtil);
        updateTimer = new Timer(1000 / 30);
        makeScene();
        addListeners();
        onActivate();
    }

    function makeFontTextures():Void {
        /*
        fontTextures = new Map();

        for (key in fonts.keys()) {
            fontTextures[key] = new GlyphTexture(utils.textureUtil, fonts[key]);
        }
        */
    }

    function makeScene():Void {

        /*
        bodies = [];
        var _id:Int = 0;
        views = [];
        */

        /*
        testBody = new TestBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(testBody);
        views.push({body:testBody, rect:new Rectangle(0, 0, 0.6, 1)});
        /**/

        /*
        uiBody = new UIBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(uiBody);

        var uiRect:Rectangle = new Rectangle(0.6, 0, 0.4, 1);
        uiRect.inflate(-0.025, -0.1);

        views.push({body:uiBody, rect:uiRect});
        uiBody.updateText(text);
        /**/

        /*
        var alphabetBody:Body = new AlphabetBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(alphabetBody);
        views.push({body:alphabetBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        /*
        splashBody = new SplashBody(_id++, utils.bufferUtil, fontTextures["full"], redrawHitAreas);
        bodies.push(splashBody);
        views.push({body:splashBody, rect:new Rectangle(0, 0, 1, 1)});
        /**/

        if (OpenGLView.isSupported) {
            view = new OpenGLView();
            createProgram();

            var vertices:Array<Float> = [
                100, 100, 0,
                -100, 100, 0,
                100, -100, 0,
                -100, -100, 0
            ];

            vertexBuffer = GL.createBuffer();
            GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
            GL.bufferData(GL.ARRAY_BUFFER, new Float32Array(cast vertices), GL.STATIC_DRAW);
            view.render = renderView;
            stage.addChild(view);
        } else {
            trace("OpenGLView isn't supported.");
        }
    }

    function addListeners():Void {
        //stage.addEventListener(Event.RESIZE, onResize);
        stage.addEventListener(Event.ACTIVATE, onActivate);
        stage.addEventListener(Event.DEACTIVATE, onDeactivate);

        // mouseSystem.view.addEventListener(MouseEvent.CLICK, onMouseViewClick);
    }

    function createProgram():Void {
        var vertexShaderSource:String =
        "
            attribute vec3 vertexPosition;
            uniform mat4 modelViewMatrix;
            uniform mat4 projectionMatrix;
            void main(void) {
                gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
            }
        ";

        var vertexShader:GLShader = GL.createShader(GL.VERTEX_SHADER);

        GL.shaderSource(vertexShader, vertexShaderSource);
        GL.compileShader(vertexShader);

        if (GL.getShaderParameter(vertexShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling vertex shader";
        }

        var fragmentShaderSource:String =
        "
            void main(void) {
                gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
            }
        ";

        var fragmentShader:GLShader = GL.createShader(GL.FRAGMENT_SHADER);

        GL.shaderSource(fragmentShader, fragmentShaderSource);
        GL.compileShader(fragmentShader);

        if (GL.getShaderParameter(fragmentShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling fragment shader";
        }

        shaderProgram = GL.createProgram();
        GL.attachShader(shaderProgram, vertexShader);
        GL.attachShader(shaderProgram, fragmentShader);
        GL.linkProgram(shaderProgram);

        if (GL.getProgramParameter(shaderProgram, GL.LINK_STATUS) == 0) {
            throw "Unable to initialize the shader program.";
        }

        GL.useProgram(shaderProgram);
        vertexAttribute = GL.getAttribLocation(shaderProgram, "vertexPosition");
        GL.enableVertexAttribArray(vertexAttribute);
    }

    function renderView(rect:Rectangle):Void {
        if (this.rect == null || !rect.equals(this.rect)) {
            this.rect = rect;
            onResize();
            doStuff();
        }
    }

    function onResize(?event:Event):Void {
        // for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        // mouseSystem.setSize(stage.stageWidth, stage.stageHeight);
        // renderer.setSize(stage.stageWidth, stage.stageHeight);
    }

    function onActivate(?event:Event):Void {
        if (active) return;
        active = true;

        stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
        updateTimer.addEventListener(TimerEvent.TIMER, onTimer);
        lastTimeStamp = HaxeTimer.stamp();
        updateTimer.start();
        onResize();
        onTimer();
        onEnterFrame();
        // renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onDeactivate(?event:Event):Void {
        if (!active) return;
        active = false;

        updateTimer.removeEventListener(TimerEvent.TIMER, onTimer);
        updateTimer.stop();
        stage.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    function onTimer(?event:Event):Void {
        var timeStamp:Float = HaxeTimer.stamp();
        update(timeStamp - lastTimeStamp);
        lastTimeStamp = timeStamp;
    }

    function redrawHitAreas():Void {
        update(0);
        // renderer.render(bodies, mouseMethod, RenderDestination.MOUSE);
    }

    function onMouseViewClick(?event:Event):Void {
        redrawHitAreas();
    }

    function update(delta:Float):Void {

        var numX:Float = (stage.mouseX / stage.stageWidth) * 2 - 1;
        var numY:Float = (stage.mouseY / stage.stageHeight) * 2 - 1;

        var bodyMat:Matrix3D;

        /*
        if (testBody != null) {
            bodyMat = testBody.transform;
            bodyMat.identity();
            spinBody(testBody, numX, numY);
            bodyMat.appendTranslation(0, 0, 0.5);
        }

        if (splashBody != null) {
            bodyMat = splashBody.transform;
            bodyMat.identity();
            spinBody(splashBody, 0, 0.5);
            spinBody(splashBody, numX * -0.04, 0.08);
            bodyMat.appendTranslation(0, 0.5, 0.5);
        }
        */

        //if (uiBody != null) uiBody.scrollTextToRatio(stage.mouseY / stage.stageHeight);

        /*
        var divider:Float = stage.mouseX / stage.stageWidth;
        views[0].rect.right = divider;
        views[1].rect.left  = divider;

        for (view in views) view.body.adjustLayout(stage.stageWidth, stage.stageHeight, view.rect);
        /**/

        //for (body in bodies) body.update(delta);
    }

    /*
    function spinBody(body:Body, numX:Float, numY:Float):Void {
        body.transform.appendRotation(-numX * 360 - 180     , Vector3D.Z_AXIS);
        body.transform.appendRotation(-numY * 360 - 180 + 90, Vector3D.X_AXIS);
    }
    */

    function interact(bodyID:Int, glyphID:Int, interaction:Interaction, stageX:Float, stageY:Float/*, delta:Float*/):Void {
        /*
        if (bodyID >= bodies.length) return;
        var view:View = views[bodyID];
        var x:Float = (stageX / stage.stageWidth  - view.rect.x) / view.rect.width;
        var y:Float = (stageY / stage.stageHeight - view.rect.y) / view.rect.height;
        view.body.interact(glyphID, interaction, x, y); // , delta
        */
    }

    function onEnterFrame(?event:Event):Void {
        // renderer.render(bodies, prettyMethod, RenderDestination.SCREEN);
        doStuff();
    }

    function doStuff():Void {

        GL.viewport(Std.int(rect.x), Std.int(rect.y), Std.int(rect.width), Std.int(rect.height));
        GL.clearColor(0, 0, 0, 1.0);
        GL.clear(GL.COLOR_BUFFER_BIT);

        var positionX:Float = rect.width / 2;
        var positionY:Float = rect.height / 2;
        var projectionMatrix:Matrix3D = Matrix3D.createOrtho(0, rect.width, rect.height, 0, 1000, -1000);
        var modelViewMatrix:Matrix3D = Matrix3D.create2D(positionX, positionY, 1, 0);

        GL.bindBuffer(GL.ARRAY_BUFFER, vertexBuffer);
        GL.vertexAttribPointer(vertexAttribute, 3, GL.FLOAT, false, 0, 0);

        var projectionMatrixUniform:GLUniformLocation = GL.getUniformLocation(shaderProgram, "projectionMatrix");
        var modelViewMatrixUniform:GLUniformLocation = GL.getUniformLocation(shaderProgram, "modelViewMatrix");

        GL.uniformMatrix3D(projectionMatrixUniform, false, projectionMatrix);
        GL.uniformMatrix3D(modelViewMatrixUniform, false, modelViewMatrix);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);
    }

}
