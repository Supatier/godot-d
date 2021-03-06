module godot.d.reference;

import std.meta, std.traits, std.typecons;

import godot.core, godot.c;
import godot.reference, godot.object;
import godot.d.meta, godot.d.script;

/// Ref-counted container for Reference types
struct Ref(T) if(extends!(T, Reference))
{
	@nogc nothrow:
	
	static if(isGodotBaseClass!T)
	{
		package(godot) T _reference;
		alias _self = _reference;
	}
	else
	{
		package(godot) T _self;
		pragma(inline, true)
		package(godot) inout(GodotClass!T) _reference() inout
		{
			return (_self) ? _self.owner : GodotClass!T.init;
		}
	}
	
	/++
	Returns the reference without allowing it to escape the calling scope.
	+/
	ref inout(T) refPayload() inout return
	{
		return _self;
	}
	alias refPayload this;
	
	void addref(U)(Ref!U other) if(__traits(compiles, _self = other._self))
	{
		_self = other._self;
		if(_self) _reference.reference();
	}
	
	ref Ref opAssign(U)(Ref!U other) if(__traits(compiles, _self = other._self))
	{
		if(this == other) return this;
		unref();
		addref(other);
		return this;
	}
	
	ref Ref opAssign(Variant v)
	{
		unref();
		_self = v.as!T;
		return this;
	}
	
	void unref()
	{
		if(_self && _reference.unreference())
		{
			_godot_api.godot_object_destroy(_reference._godot_object);
		}
		_self = T.init;
	}
	
	pragma(inline, true)
	bool opEquals(U)(in Ref!U other) const
	{
		return _reference._godot_object == other._reference._godot_object;
	}
	
	pragma(inline, true)
	bool isValid() const { return _reference != GodotClass!T.init; }
	alias opCast(T : bool) = isValid;
	pragma(inline, true)
	bool isNull() const { return _reference == GodotClass!T.init; }
	
	this(this)
	{
		if(_self) _reference.reference();
	}
	
	/++
	Construct from other Ref
	+/
	this(U)(Ref!U other) if(__traits(compiles, _self = other._self))
	{
		addref(other);
	}
	
	this(in Variant v)
	{
		_self = v.as!T;
	}
	
	~this()
	{
		unref();
	}
}

/++
Create a Ref from a pointer without incrementing refcount.
+/
package(godot) RefOrT!T refOrT(T)(T instance)
{
	static if(extends!(T, Reference))
	{
		Ref!T ret = void;
		ret._self = instance;
		return ret;
	}
	else return instance;
}

/++
Create a Ref from a pointer and increment refcount.
+/
package(godot) RefOrT!T refOrTInc(T)(T instance)
{
	static if(extends!(T, Reference))
	{
		Ref!T ret = void;
		ret._self = instance;
		if(ret._self) ret._reference.reference();
		return ret;
	}
	else return instance;
}


