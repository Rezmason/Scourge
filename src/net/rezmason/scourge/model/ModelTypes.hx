package net.rezmason.scourge.model;

import net.rezmason.scourge.model.Aspect;

typedef AspectRequirements = IntHash<Class<Aspect>>;
typedef Aspects = IntHash<Aspect>;
typedef BoardNode = GridNode<Aspects>;
typedef HistoryAllocator = Int->Int;

typedef BoardData = {heads:Array<Int>, nodes:Array<BoardNode>};
