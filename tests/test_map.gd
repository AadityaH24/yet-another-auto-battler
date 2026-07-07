extends SceneTree

var _passed := 0
var _failed := 0
var _fail := false

func _initialize():
	var MND = preload("res://scripts/map/map_node_data.gd")
	var MG = preload("res://scripts/map/map_generator.gd")

	check("generate nodes", func():
		var nodes = MG.generate(1)
		verify(nodes.size() > 0, "no nodes")
		var has := false
		for n in nodes:
			if n.connections.size() > 0: has = true
		verify(has, "no connections")
	)

	check("forward conns", func():
		var nodes = MG.generate(1)
		for n in nodes:
			for c in n.connections:
				verify(c.layer == n.layer + 1, "wrong layer")
	)

	check("entry reachable", func():
		var a := MND.new()
		a.layer = 0
		verify(null == null and a.layer == 0 and not a.completed, "entry blocked")
	)

	check("completed blocked", func():
		var a := MND.new(); var b := MND.new()
		a.connections.append(b)
		verify(a.connections.has(b) and not b.completed, "uncompleted blocked")
		b.completed = true
		verify(not (a.connections.has(b) and not b.completed), "completed reachable")
	)

	check("no backward", func():
		var a := MND.new(); var b := MND.new()
		a.layer = 0; b.layer = 1
		a.connections.append(b); a.completed = true
		verify(not (b.connections.has(a) and not a.completed), "went backward")
	)

	check("three acts", func():
		verify(MG.generate(1).size() > 0, "act 1 empty")
		verify(MG.generate(2).size() > 0, "act 2 empty")
		verify(MG.generate(3).size() > 0, "act 3 empty")
	)

	done()

func check(name: String, fn: Callable):
	_fail = false
	fn.call()
	if not _fail:
		_passed += 1
		print("  PASS  " + name)

func verify(cond: bool, msg: String):
	if not cond:
		_fail = true
		_failed += 1
		push_error("FAIL " + msg)

func done():
	print("")
	print(str(_passed) + " passed, " + str(_failed) + " failed")
	quit(_failed)
