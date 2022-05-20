extends MenuButton
tool

var editor_selection : EditorSelection
var initialized : bool
var tools : Array
var directions : Array
var overwrite : bool
var targets : Array

enum PopupIdName {EIGHT_MODE, OVERWRITE, CHECK_TARGET, __SEPARATOR__, SURROUND_TILES, TILE_OUTERMOST, TILE_ALL}

enum DirectionMode {FOUR, EIGHT}
var direction_mode : int setget set_direction_mode
func set_direction_mode(val : int):
	direction_mode = val
	match direction_mode:
		DirectionMode.FOUR:
			directions = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
		DirectionMode.EIGHT:
			directions = [Vector2.RIGHT, Vector2.ONE, Vector2.DOWN, Vector2(-1, 1), Vector2.LEFT, Vector2.ONE * -1, Vector2.UP, Vector2(1, -1)]

func _init_selection(esel : EditorSelection) -> void:
	if !is_instance_valid(esel):
		printerr("Tile Map Tools: Passed invalid EditorSelection, couldn't initialize tools")
		return
	editor_selection = esel
	editor_selection.connect("selection_changed", self, "_on_editor_selection_changed")

func _init_popup() -> void:
	var _popup = get_popup()
	_popup.hide_on_checkable_item_selection = false
	_popup.connect("id_pressed", self, "_on_popup_id_pressed")
	_popup.add_check_item("Eight Mode")
	_popup.add_check_item("Overwrite")
	_popup.add_item("Check Target")
	_popup.add_separator("")
	_popup.add_item("Surround Tile")
	_popup.add_item("Tile Outermost")
	_popup.add_item("Tile All")

func _init_self() -> void:
	text = "Tools"
	set_direction_mode(DirectionMode.FOUR)
	initialized = true

func _init(esel : EditorSelection) -> void:
	_init_selection(esel)
	_init_popup()
	_init_self()

func _on_editor_selection_changed() -> void:
	var _tilemaps = get_tilemaps_in_selection()
	if _tilemaps.empty():
		hide()
		targets.clear()
		return
	
	show()
	
	var _i = targets.size() - 1
	while _i >= 0:
		if _tilemaps.find(targets[_i]) == -1:
			targets.remove(_i)
		_i -= 1
	
	for t in _tilemaps:
		if !targets.has(t):
			targets.push_back(t)

func _on_popup_id_pressed(id : int) -> void:
	match id:
		PopupIdName.EIGHT_MODE:
			var _popup = get_popup()
			_popup.set_item_checked(id, !_popup.is_item_checked(id))
			if _popup.is_item_checked(id):
				set_direction_mode(DirectionMode.EIGHT)
			else:
				set_direction_mode(DirectionMode.FOUR)
		PopupIdName.OVERWRITE:
			var _popup = get_popup()
			_popup.set_item_checked(id, !_popup.is_item_checked(id))
			overwrite = _popup.is_item_checked(id)
		PopupIdName.CHECK_TARGET:
			print("List of targets (0 = source, 1 = destination, 2... = unused)")
			for i in targets.size():
				print(i, ": ", targets[i].name)
		PopupIdName.SURROUND_TILES:
			_surround_tiles()
		PopupIdName.TILE_OUTERMOST:
			_tile_outermost()
		PopupIdName.TILE_ALL:
			_tile_all()

func get_tilemaps_in_selection() -> Array:
	var _sel = editor_selection.get_selected_nodes()
	var _tilemaps = []
	for n in _sel:
		if n is TileMap:
			_tilemaps.push_back(n)
	return _tilemaps

func _surround_tiles() -> void:
	if targets.size() < 2:
		printerr("Surround tiles needs at least two TileMap nodes to work")
		return
	
	var _src : TileMap = targets[0]
	var _dest : TileMap = targets[1]
	print("Source: ", _src.name)
	print("Destination: ", _dest.name)
	
	for pos in _src.get_used_cells():
		if _src.get_cellv(pos) != TileMap.INVALID_CELL:
			for dir in directions:
				if _src.get_cellv(pos + dir) == TileMap.INVALID_CELL:
					_dest.set_cellv(pos + dir, 0)
				elif overwrite:
					_dest.set_cellv(pos + dir, TileMap.INVALID_CELL)

func _tile_outermost() -> void:
	if targets.size() < 2:
		printerr("Tile All needs at least two TileMap nodes to work")
		return
	
	var _src : TileMap = targets[0]
	var _dest : TileMap = targets[1]
	var _used_rect : Rect2 = _src.get_used_rect()
	
	for x in range(_used_rect.position.x - 1, _used_rect.end.x + 1):
		for y in range(_used_rect.position.y - 1, _used_rect.end.y + 1):
			if _src.get_cell(x, y) == TileMap.INVALID_CELL:
				for dir in directions:
					if _src.get_cell(x + dir.x, y + dir.y) != TileMap.INVALID_CELL:
						_dest.set_cell(x + dir.x, y + dir.y, 0)
					elif overwrite:
						_dest.set_cell(x + dir.x, y + dir.y, TileMap.INVALID_CELL)

func _tile_all() -> void:
	if targets.size() < 2:
		printerr("Tile All needs at least two TileMap nodes to work")
		return
	
	var _src : TileMap = targets[0]
	var _dest : TileMap = targets[1]
	
	for pos in _src.get_used_cells():
		_dest.set_cellv(pos, 0)
