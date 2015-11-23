package net.rezmason.scourge.controller;

import box2D.collision.shapes.B2CircleShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2CairoDebugDraw;
import box2D.dynamics.B2DebugDrawFlag;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import box2D.dynamics.joints.B2DistanceJointDef;

import net.rezmason.scourge.textview.core.DebugGraphics;
import net.rezmason.utils.santa.Present;

class BoardManipulator {

    var world:B2World;
    var b0:B2Body;
    var b1:B2Body;
    
    public function new() {
        world = new B2World(new B2Vec2(0, 0), true);
        #if debug_graphics
            var debugDraw = new B2CairoDebugDraw();
            var cairo:DebugGraphics = new Present(DebugGraphics);
            debugDraw.setCairo(cairo);
            debugDraw.setLineThickness(1 / 400);
            debugDraw.setDrawScale(1 / 10);
            world.setDebugDraw(debugDraw);
            debugDraw.setFlags(Shapes | Joints | CentersOfMass);
        #end

        world.setWarmStarting(true); // necessary?

        var fixtureDef = new B2FixtureDef();
        fixtureDef.filter.groupIndex = -1;
        var bodyDef = new B2BodyDef();
        bodyDef.type = DYNAMIC_BODY;
        fixtureDef.shape = new B2CircleShape(0.25);
        fixtureDef.density = 100;
        bodyDef.position.set(5, 5);
        b0 = world.createBody(bodyDef);
        b0.createFixture(fixtureDef);

        bodyDef.type = STATIC_BODY;
        b1 = world.createBody(bodyDef);

        var djd = new B2DistanceJointDef();
        
        djd.initialize(b0, b1, new B2Vec2(5, 5), new B2Vec2(2.5, 5));
        djd.dampingRatio = 0.0;
        djd.frequencyHz = 1;
        world.createJoint(djd);

        djd.initialize(b0, b1, new B2Vec2(5, 5), new B2Vec2(7.5, 5));
        djd.dampingRatio = 0.0;
        djd.frequencyHz = 1;
        world.createJoint(djd);

        djd.initialize(b0, b1, new B2Vec2(5, 5), new B2Vec2(5, 7.5));
        djd.dampingRatio = 0.0;
        djd.frequencyHz = 1;
        world.createJoint(djd);

        djd.initialize(b0, b1, new B2Vec2(5, 5), new B2Vec2(5, 2.5));
        djd.dampingRatio = 0.0;
        djd.frequencyHz = 1;
        world.createJoint(djd);

        b0.setPosition(new B2Vec2(5, 7.5));
        b0.setLinearVelocity(new B2Vec2(10, 0));
    }

    public function update(delta) {
        world.step(delta, 10, 10);
        world.clearForces();
        #if debug_graphics world.drawDebugData(); #end
    }
}
