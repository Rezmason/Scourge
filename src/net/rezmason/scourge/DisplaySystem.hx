package net.rezmason.scourge;

import flash.geom.Rectangle;

import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Engine;

typedef Region = {
    var rect:Rectangle;
    var occupierName:String;
}

class DisplaySystem {

    var engine:Engine;

    var bodiesByName:Map<String, Body>;
    var regionsByName:Map<String, Region>;

    public function new(engine:Engine):Void {
        this.engine = engine;
        bodiesByName = new Map();
        regionsByName = new Map();
    }

    public function addBody(bodyName:String, body:Body, regionName:String = null):Void {
        if (bodiesByName[bodyName] == null) {
            bodiesByName[bodyName] = body;
            if (regionName != null) showBody(bodyName, regionName);
        } else {
            throw 'There already is a body with the name $bodyName';
        }
    }

    public function removeBody(bodyName:String):Void {
        if (bodiesByName[bodyName] != null) {
            engine.removeBody(bodiesByName[bodyName]);
            bodiesByName[bodyName] = null;
        }
    }

    public function hasBody(bodyName:String):Bool return bodiesByName.exists(bodyName);

    public function addRegion(regionName:String, rect:Rectangle):Void {
        if (regionsByName[regionName] == null) regionsByName[regionName] = cast {rect:rect.clone(), occupier:null};
        else throw 'There already is a region with the name $regionName';
    }

    public function removeRegion(regionName:String):Void {
        clearRegion(regionName);
        regionsByName[regionName] = null;
    }

    public function hasRegion(regionName:String):Bool return regionsByName.exists(regionName);

    public function showBody(bodyName:String, regionName:String):Void {
        if (bodiesByName[bodyName] == null) throw 'There is no body with the name $bodyName';
        if (regionsByName[regionName] == null) throw 'There is no region with the name $regionName';
        if (bodiesByName[regionsByName[regionName].occupierName] != null) hideBody(regionsByName[regionName].occupierName);

        regionsByName[regionName].occupierName = bodyName;
        var body:Body = bodiesByName[bodyName];
        body.viewRect = regionsByName[regionName].rect;
        engine.addBody(body);
    }

    public function hideBody(bodyName:String):Void {
        if (bodiesByName[bodyName] == null) throw 'There is no body with the name $bodyName';
        engine.removeBody(bodiesByName[bodyName]);
    }

    public function clearRegion(regionName:String):Void {
        if (regionsByName[regionName].occupierName != null) hideBody(regionsByName[regionName].occupierName);
    }
}
