package net.rezmason.scourge.controller;

import box2D.collision.shapes.B2CircleShape;
import box2D.collision.shapes.B2PolygonShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2DebugDrawFlag;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import box2D.dynamics.joints.B2DistanceJoint;
import box2D.dynamics.joints.B2DistanceJointDef;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.core.DebugDisplay;
import net.rezmason.hypertype.ui.DragBehavior;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

#if debug_graphics
    import box2D.dynamics.B2CairoDebugDraw;
#end

class BoardDragBehavior extends DragBehavior {

    public var horizontalWrapSignal(default, null):Zig<Int->Void> = new Zig();
    public var verticalWrapSignal(default, null):Zig<Int->Void> = new Zig();

    var world:B2World;
    var marble:B2Body;
    var marblePos:Vec3;
    var thumb:B2Body;
    var spring:B2DistanceJoint;
    var northWall:B2Body;
    var southWall:B2Body;
    var eastWall:B2Body;
    var westWall:B2Body;
    
    public function new() {
        super();
        world = new B2World(new B2Vec2(0, 0), true);
        
        #if debug_graphics
            var debugDraw = new B2CairoDebugDraw();
            var debugDisplay:DebugDisplay = new Present(DebugDisplay);
            debugDraw.setCairo(debugDisplay.cairo);
            debugDraw.setLineThickness(1 / 400);
            debugDraw.setDrawScale(1);
            world.setDebugDraw(debugDraw);
            debugDraw.setFlags(Shapes | Joints);
        #end

        var fixtureDef = new B2FixtureDef();
        var bodyDef = new B2BodyDef();
        var origin = new B2Vec2();

        // Marble
        bodyDef.type = DYNAMIC_BODY;
        fixtureDef.shape = new B2CircleShape(0.05);
        fixtureDef.density = 50;
        marble = world.createBody(bodyDef);
        marble.createFixture(fixtureDef);
        marble.setLinearDamping(4);
        marblePos = new Vec3(0, 0, 0);

        // Thumb
        bodyDef.type = KINEMATIC_BODY;
        thumb = world.createBody(bodyDef);
        fixtureDef.filter.groupIndex = -1;
        thumb.createFixture(fixtureDef);
        thumb.setActive(false);

        // Spring
        var djd = new B2DistanceJointDef();
        djd.initialize(marble, thumb, origin, origin);
        djd.dampingRatio = 0.2;
        djd.frequencyHz = 1;
        spring = cast world.createJoint(djd);

        // Walls
        bodyDef.type = STATIC_BODY;
        var wallShape:B2PolygonShape = new B2PolygonShape();
        fixtureDef.shape = wallShape;
        function makeWall(x, y, w, h) {
            bodyDef.position.set(x, y);
            wallShape.setAsBox(w, h);
            var wall = world.createBody(bodyDef);
            wall.createFixture(fixtureDef);
            wall.setActive(false);
            return wall;
        }
        southWall = makeWall( 0.0, -0.4, 0.50, 0.05);
        northWall = makeWall( 0.0,  0.4, 0.50, 0.05);
        westWall  = makeWall(-0.4,  0.0, 0.05, 0.50);
        eastWall  = makeWall( 0.4,  0.0, 0.05, 0.50);
    }

    override public function update(delta) {
        world.step(delta, 10, 10);
        world.clearForces();

        settling = !dragging && marble.isAwake();
        
        if (marble.isAwake()) {
            
            var thumbPosition = thumb.getPosition();
            var marblePosition = marble.getPosition();
            var marbleLinearVelocity = marble.getLinearVelocity();

            // Wrap marble's position
            var horizontalWrap:Int = Std.int(Math.floor(marblePosition.x + 0.5));
            var verticalWrap:Int   = Std.int(Math.floor(marblePosition.y + 0.5));
            marblePosition.x -= horizontalWrap;
            thumbPosition.x -= horizontalWrap;
            marblePosition.y -= verticalWrap;
            thumbPosition.y -= verticalWrap;
            marble.setPosition(marblePosition);
            thumb.setPosition(thumbPosition);

            // Apply field force to marble
            var piX = Math.PI * marblePosition.x;
            var piY = Math.PI * marblePosition.y;
            var forceX = getFieldXSlope(piX, piY) * 5;
            var forceY = getFieldYSlope(piX, piY) * 5;
            marble.applyForce(new B2Vec2(forceX, forceY), marble.getPosition());

            // Update behavior properties
            var marblePosition = marble.getPosition();
            marblePos.x = marblePosition.x;
            marblePos.y = marblePosition.y;

            // Broadcast wrap events
            if (marbleLinearVelocity.x > marbleLinearVelocity.y) {
                if (horizontalWrap != 0) horizontalWrapSignal.dispatch(horizontalWrap);
                if (verticalWrap   != 0) verticalWrapSignal.dispatch(verticalWrap);
            } else {
                if (verticalWrap   != 0) verticalWrapSignal.dispatch(verticalWrap);
                if (horizontalWrap != 0) horizontalWrapSignal.dispatch(horizontalWrap);
            }
        }

        #if debug_graphics world.drawDebugData(); #end
    }

    override public function startDrag(x, y) {
        if (!dragging) {
            super.startDrag(x, y);
            thumb.setActive(true);
            var thumbPosition = thumb.getPosition();
            var marblePosition = marble.getPosition();
            thumbPosition.x = marblePosition.x;
            thumbPosition.y = marblePosition.y;
            thumb.setPosition(thumbPosition);
            thumb.setAwake(true);
            marble.setAwake(true);
        }
    }

    override public function updateDrag(x, y) {
        if (dragging) {
            super.updateDrag(x, y);
            var thumbPosition = thumb.getPosition();
            thumbPosition.x += pos.x - lastPos.x;
            thumbPosition.y += pos.y - lastPos.y;
            thumb.setPosition(thumbPosition);
            thumb.setAwake(true);
            marble.setAwake(true);
        }
    }

    override public function stopDrag() {
        if (dragging) {
            dragging = false;
            thumb.setActive(false);
            settling = marble.isAwake();
        }
    }

    inline function getFieldHeight(piX:Float, piY:Float) return Math.pow(Math.cos(piX) * Math.cos(piY), 2);
    inline function getFieldXSlope(piX:Float, piY:Float) return -Math.sin(2 * piX) * Math.pow(Math.cos(piY), 2);
    inline function getFieldYSlope(piX:Float, piY:Float) return getFieldXSlope(piY, piX);

    public function setWalls(north, south, east, west) {
        northWall.setActive(north);
        southWall.setActive(south);
        eastWall.setActive(east);
        westWall.setActive(west);
    }

    override function get_displacement() return marblePos;
}
