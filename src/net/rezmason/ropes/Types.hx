package net.rezmason.ropes;

import net.rezmason.ropes.Aspect;

using net.rezmason.utils.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectProperty = { var id(default, null):Int; var initialValue(default, null):Atom; }; // The distinct possible properties of our state
typedef AspectRequirements = Array<AspectProperty>;
typedef AspectPtr = Ptr<Atom>;
typedef AspectSet = Array<Atom>; // The properties of an element of the state
typedef AspectLookup = Array<AspectPtr>; // The indices of property types in the AspectSet of an element
typedef BoardNode = GridNode<AspectSet>;
typedef Option = {optionID:Int, ?relatedOptionID:Int, ?weight:Float};
typedef SavedState = {data:String};
typedef StateHistory = History<Atom>;
