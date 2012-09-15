package net.rezmason.scourge.model;

import net.rezmason.scourge.model.Aspect;

using net.rezmason.utils.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectProperty = {id:Int, initialValue:Atom}; // The distinct possible properties of our state
typedef AspectRequirements = Array<AspectProperty>;
typedef AspectPtr = Ptr<Atom>;
typedef AspectSet = Array<Atom>; // The properties of an element of the state
typedef AspectLookup = Array<AspectPtr>; // The indices of property types in the AspectSet of an element
typedef BoardNode = GridNode<AspectSet>;
typedef Option = {optionID:Int};

typedef StateHistory = History<Atom>;
