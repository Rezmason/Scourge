package net.rezmason.scourge.controller;

import box2D.collision.shapes.B2CircleShape;
import box2D.collision.shapes.B2PolygonShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2DebugDrawFlag;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import box2D.dynamics.joints.B2DistanceJointDef;
import box2D.dynamics.joints.B2DistanceJoint;

import net.rezmason.scourge.textview.core.DebugGraphics;
import net.rezmason.utils.santa.Present;

#if debug_graphics
    import box2D.dynamics.B2CairoDebugDraw;
#end

class BoardManipulator {

    var world:B2World;
    var marble:B2Body;
    var thumb:B2Body;
    var spring:B2DistanceJoint;
    var northWall:B2Body;
    var southWall:B2Body;
    var eastWall:B2Body;
    var westWall:B2Body;
    
    public function new() {
        world = new B2World(new B2Vec2(0, 0), true);
        #if debug_graphics
            var debugDraw = new B2CairoDebugDraw();
            var cairo:DebugGraphics = new Present(DebugGraphics);
            debugDraw.setCairo(cairo);
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
        northWall = makeWall( 0.0, -0.4, 0.50, 0.05);
        southWall = makeWall( 0.0,  0.4, 0.50, 0.05);
        westWall  = makeWall(-0.4,  0.0, 0.05, 0.50);
        eastWall  = makeWall( 0.4,  0.0, 0.05, 0.50);
    }

    public function update(delta) {
        world.step(delta, 10, 10);
        world.clearForces();

        if (marble.isAwake()) {
            // Loop marble's position

            var horizontal:Int = 0;
            var vertical:Int = 0;

            var marblePosition = marble.getPosition();
            var thumbPosition = thumb.getPosition();
            while (marblePosition.x > 0.5) {
                marblePosition.x--;
                thumbPosition.x--;
                horizontal++;
            }
            while (marblePosition.x < -0.5) {
                marblePosition.x++;
                thumbPosition.x++;
                horizontal--;
            }
            while (marblePosition.y > 0.5) {
                marblePosition.y--;
                thumbPosition.y--;
                vertical++;
            }
            while (marblePosition.y < -0.5) {
                marblePosition.y++;
                thumbPosition.y++;
                vertical--;
            }

            if (horizontal != 0 || vertical != 0) trace('NUDGE $horizontal $vertical');

            marble.setPosition(marblePosition);
            thumb.setPosition(thumbPosition);

            // Apply field force to marble
            var piX = Math.PI * marblePosition.x;
            var piY = Math.PI * marblePosition.y;
            var forceX = getFieldXSlope(piX, piY) * 5;
            var forceY = getFieldYSlope(piX, piY) * 5;
            marble.applyForce(new B2Vec2(forceX, forceY), marble.getPosition());
        }

        #if debug_graphics world.drawDebugData(); #end
    }

    inline function getFieldHeight(piX:Float, piY:Float) return Math.pow(Math.cos(piX) * Math.cos(piY), 2);
    inline function getFieldXSlope(piX:Float, piY:Float) return -Math.sin(2 * piX) * Math.pow(Math.cos(piY), 2);
    inline function getFieldYSlope(piX:Float, piY:Float) return getFieldXSlope(piY, piX);

    public function kickMarble() {
        thumb.setActive(!thumb.isActive());
        if (thumb.isActive()) {
            thumb.setPosition(marble.getPosition());
            thumb.setLinearVelocity(new B2Vec2(
                (Math.random() * 2 - 1) * 10, 
                (Math.random() * 2 - 1) * 10
            ));
            thumb.setAwake(true);
            marble.setAwake(true);
        }
    }

    public function scrambleWalls() {
        northWall.setActive(Math.random() > 0.5);
        southWall.setActive(Math.random() > 0.5);
        eastWall.setActive(Math.random() > 0.5);
        westWall.setActive(Math.random() > 0.5);
    }
}
