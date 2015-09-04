package net.rezmason.praxis;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.grid.Cell;
import net.rezmason.grid.Grid;
import net.rezmason.grid.Selection;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.History;
using net.rezmason.utils.pointers.Pointers;

private typedef Atom = Null<Int>; // Our low-level value type

typedef AspectPtr = Ptr<Atom>;
typedef AspectSet = Pointable<Atom>; // The properties of an element of the state
typedef AspectItr = PtrIterator<Atom>;

typedef BoardCell = Cell<AspectSet>;
typedef BoardGrid = Grid<AspectSet>;
typedef BoardSelection = Selection<AspectSet>;

typedef AspectProperty = { var id(default, null):String; var initialValue(default, null):Atom; }; // The distinct possible properties of our state
typedef AspectRequirements = Map<String, AspectProperty>;
typedef AspectLookup = Map<String, AspectPtr>; // The indices of property types in the AspectSet of an element

typedef Move = {id:Int, ?relatedID:Int, ?weight:Float};
typedef SavedState = {data:String};
typedef StateHistory = History<Atom>;
typedef Rule = BaseRule<Dynamic>;
