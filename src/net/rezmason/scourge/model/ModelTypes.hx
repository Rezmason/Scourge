package net.rezmason.scourge.model;

import net.rezmason.scourge.model.Aspect;

using net.rezmason.utils.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectProperty = {id:Int, initialValue:Atom}; // The distinct possible properties of our state
typedef AspectRequirements = Array<AspectProperty>;

typedef HistPtr = Ptr<Int>;
typedef AspectPtr = Ptr<HistPtr>;

typedef AspectTemplate = Array<Atom>; // The default values required when creating a new AspectSet
typedef AspectSet = Array<HistPtr>; // The properties of an element of the state
typedef AspectLookup = Array<AspectPtr>; // The indices of property types in the AspectSet of an element

typedef StateHistory = History<Atom>;
typedef BoardNode = GridNode<AspectSet>;
