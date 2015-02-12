package net.rezmason.praxis;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.grid.GridLocus;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.History;
using net.rezmason.utils.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectPtr = Ptr<Atom>;
typedef AspectSet = PtrSet<Atom>; // The properties of an element of the state
typedef AspectItr = PtrIterator<Atom>;
typedef BoardLocus = GridLocus<AspectSet>;

typedef AspectProperty = { var id(default, null):String; var initialValue(default, null):Atom; }; // The distinct possible properties of our state
typedef AspectRequirements = Map<String, AspectProperty>;
typedef AspectLookup = Map<String, AspectPtr>; // The indices of property types in the AspectSet of an element

typedef Move = {id:Int, ?relatedID:Int, ?weight:Float};
typedef SavedState = {data:String};
typedef StateHistory = History<Atom>;
typedef Rule = BaseRule<Dynamic>;
