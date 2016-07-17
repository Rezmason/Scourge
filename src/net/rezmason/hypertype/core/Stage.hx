package net.rezmason.hypertype.core;

import lime.math.Vector4;
import net.rezmason.utils.Zig;
using Lambda;

class Stage extends Container {
    var interactiveBodiesByID:Map<Int, Body>;
    var bodies:Array<Body> = null;
    var keyboardFocusBody:Body = null;
    var pixelWidth:UInt = 72;
    var pixelHeight:UInt = 72;
    var pixelsPerInch:UInt = 72;
    var numInteractiveBodies:UInt;
    public var widthInInches(get, null):Float;
    public var heightInInches(get, null):Float;
    public var aspectRatio(get, null):Float;
    public var camera(default, null):Camera = new Camera();
    public var teaseHitboxesSignal(default, null):Zig<Bool->Void> = new Zig();
    public var toggleConsoleSignal(default, null):Zig<Void->Void> = new Zig();
    public var invalidateHitboxesSignal(default, null):Zig<Void->Void> = new Zig();
    public var resizeSignal(default, null):Zig<Void->Void> = new Zig();
    public var focus:Body;
    @:allow(net.rezmason.hypertype.core) var screenParams(default, null):Vector4 = new Vector4();

    public function new() {
        super();
        invalidateSignal.add(invalidate);
        screenParams.x = 1;
        setSize(pixelWidth, pixelHeight, pixelsPerInch);
    }

    public function setKeyboardFocus(body:Body):Void keyboardFocusBody = body;

    override public function update(delta) {
        fetchBodies();
        for (body in bodies) body.update(delta);
    }

    public function setSize(pixelWidth:UInt, pixelHeight:UInt, pixelsPerInch:UInt):Void {
        this.pixelWidth = pixelWidth;
        this.pixelHeight = pixelHeight;
        this.pixelsPerInch = pixelsPerInch;
        screenParams.x = aspectRatio;
        camera.resize(widthInInches, heightInInches);
        resizeSignal.dispatch();
    }

    public function eachBody():Iterator<Body> {
        fetchBodies();
        return bodies.iterator();
    }

    public function routeInteraction(bodyID:Null<Int>, glyphID:Null<Int>, interaction:Interaction):Void {
        fetchBodies();
        var target = null;
        switch (interaction) {
            case MOUSE(type, x, y):
                target = interactiveBodiesByID[bodyID];
                if (type == CLICK) keyboardFocusBody = target;
                if (target != null) interaction = MOUSE(type, x, y);
            case KEYBOARD(type, code, modifier):
                target = keyboardFocusBody;
                switch (code) {
                    case SPACE: teaseHitboxesSignal.dispatch(modifier.ctrlKey && type != KEY_UP);
                    case GRAVE: if (type == KEY_DOWN) toggleConsoleSignal.dispatch();
                    case _:
                }
        }
        if (target != null) target.interact(glyphID, interaction);
    }

    function invalidate():Void {
        interactiveBodiesByID = null;
        bodies = null;
        invalidateHitboxesSignal.dispatch();
    }

    inline function fetchBodies():Void {
        if (bodies == null) {
            numInteractiveBodies = 0;
            bodies = [];
            interactiveBodiesByID = new Map();
            mapBodyChildren(this);
        }
    }

    function mapBodyChildren(container:Container):Void {
        for (child in container.children()) {
            if (Std.is(child, Body)) {
                var body:Body = cast child;
                bodies.push(body);
                if (body.isInteractive) {
                    body.interactiveID = numInteractiveBodies;
                    interactiveBodiesByID[numInteractiveBodies] = body;
                    numInteractiveBodies++;
                }
            }
            mapBodyChildren(child);
        }
    }

    inline function get_aspectRatio() return pixelWidth / pixelHeight;
    inline function get_widthInInches() return pixelWidth / pixelsPerInch;
    inline function get_heightInInches() return pixelHeight / pixelsPerInch;
}
