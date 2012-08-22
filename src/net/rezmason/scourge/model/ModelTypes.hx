package net.rezmason.scourge.model;

import net.rezmason.scourge.model.Aspect;

typedef Aspects = IntHash<Aspect>;
typedef AspectRequirements = IntHash<Class<Aspect>>;
typedef AspectTemplate = Array<Int>;

typedef BoardNode = GridNode<Aspects>;

typedef BoardData = {heads:Array<Int>, nodes:Array<BoardNode>};
