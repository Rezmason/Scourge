package net.rezmason.ecce;

import massive.munit.Assert;

class EcceTest {
    
    @Test
    public function ecceTest():Void {
        var ecce = new Ecce();
        
        var q0 = ecce.query([]);
        var q1 = ecce.query([Thing1]);
        var q2 = ecce.query([Thing1]);
        var q3 = ecce.query([Thing2]);
        var q4 = ecce.query([Thing3]);

        var e1 = ecce.dispense([Thing1]);
        var e2 = ecce.dispense([Thing2]);
        var e3 = ecce.dispense([Thing3]);

        var e4 = ecce.dispense();
        e4.add(Thing1);
        e4.remove(Thing1);
        e4.add(Thing1);

        e4.get(Thing1);

        ecce.query([Thing3]);
        try {
            ecce.query([Thing2, Thing3]);
            Assert.fail('Ecce should not allow new queries after entities are dispensed');
        } catch (e:String) {}
        
        var e5 = ecce.dispense([Thing1, Thing2]);
        var e6 = ecce.dispense([Thing2, Thing3]);
        var e7 = ecce.dispense([Thing3, Thing1]);

        for (e in ecce.get([Thing2])) trace(e.get(Thing2));

        for (e in q2) trace(e.get(Thing1));

        var classes:Array<Class<Dynamic>> = [Thing1, Thing2, Thing3];

        for (ike in 0...1000) {
            var t = classes[Std.random(3)];
            e7.add(t);
            t = classes[Std.random(3)];
            e7.remove(t);
        }
    }
}

class Thing1 { public function new() {} }
class Thing2 { public function new() {} }
class Thing3 { public function new() {} }
