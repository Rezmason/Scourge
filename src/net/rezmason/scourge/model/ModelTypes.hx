package net.rezmason.scourge.model;

import net.rezmason.scourge.model.aspects.Aspect;

typedef AspectRequirements = IntHash<Class<Aspect>>;
typedef BoardNode = GridNode<IntHash<Aspect>>;
