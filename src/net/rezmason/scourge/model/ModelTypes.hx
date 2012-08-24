package net.rezmason.scourge.model;

import net.rezmason.scourge.model.Aspect;

typedef AspectProperty = {id:Int, initialValue:Int};

typedef Aspects = Array<Int>;
typedef AspectTemplate = Array<Int>;
typedef AspectLookup = Array<Int>;
typedef AspectRequirements = Array<AspectProperty>;

typedef StateHistory = History<Null<Int>>;

typedef BoardNode = GridNode<Aspects>;

typedef BoardData = {heads:Array<Int>, nodes:Array<BoardNode>};
