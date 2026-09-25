extends "res://scripts/main.gd"

var barn_interior: FarmBarnInterior
var animals: FarmAnimalSystem
var animal_panel: FarmAnimalPanel

const BARN_OUTSIDE_DOOR := Vector2(435, 1374)

func _ready() -> void:
	super()

	# Extend the existing v0.7 economy with animal products.
	produce_inventory["egg"] = int(produce_inventory.get("egg", 0))
	produce_inventory["milk"] = int(produce_inventory.get("milk", 0))
	shipping_pending["egg"] = int(shipping_pending.get("egg", 0))
	shipping_pending["milk"] = int(shipping_pending.get("milk", 0))
	storage_inventory["egg"] = int(storage_inventory.get("egg", 0))
	storage_inventory["milk"] = int(storage_inventory.get("milk", 0))
	sell_prices["egg"] = 80
	sell_prices["milk"] = 180

	barn_interior = FarmBarnInterior.new()
	barn_interior.name = "BarnInterior"
	add_child(barn_interior)

	animals = FarmAnimalSystem.new()
	animals.name = "AnimalSystem"
	add_child(animals)
	animals.set_active(false)

	animal_panel = FarmAnimalPanel.new()
	animal_panel.name = "AnimalPanel"
	add_child(animal_panel)
	animal_panel.open_state_changed.connect(_on_animal_panel_state_changed)
	animal_panel.buy_animal_requested.connect(_on_buy_animal_requested)
	animal_panel.buy_feed_requested.connect(_on_buy_feed_requested)

	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	ui.show_message("v0.8: The barn is open. Raise chickens and cows, feed them, pet them, and collect eggs or milk.")

func _get_near_interaction() -> Dictionary:
	if interiors.active_room == "barn":
		var animal_interaction := animals.get_interaction(player.position)
		if not animal_interaction.is_empty():
			return animal_interaction
		return barn_interior.get_interaction(player.position)

	if interiors.active_room == "outside" and player.position.distance_to(BARN_OUTSIDE_DOOR) < 105.0:
		return {"type":"barn_entry", "name":"Enter Barn"}

	return super._get_near_interaction()

func _handle_interaction(data: Dictionary) -> void:
	var kind := String(data.get("type", ""))
	match kind:
		"barn_entry":
			_enter_interior("barn")
		"barn_exit":
			_exit_interior()
		"animal_ledger":
			_open_animal_panel()
		"feed_trough":
			var result := animals.feed_animals()
			var fed_count := int(result.get("fed", 0))
			if animals.animals.is_empty():
				ui.show_message("The barn is empty. Use the Animal Ledger to buy your first animal.")
			elif fed_count <= 0:
				if animals.feed_stock <= 0:
					ui.show_message("You're out of feed. Buy more from the Animal Ledger.")
				else:
					ui.show_message("Every animal has already been fed today.")
			else:
				ui.show_message("Fed %d animal%s. Feed remaining: %d." % [fed_count, "" if fed_count == 1 else "s", animals.feed_stock])
		"animal_products":
			_collect_animal_products()
		"animal":
			_pet_animal()
		_:
			super._handle_interaction(data)

func _enter_interior(room: String) -> void:
	if room != "barn":
		super._enter_interior(room)
		return
	inventory_ui.close_panel()
	ui.close_shop()
	if animal_panel and animal_panel.is_open:
		animal_panel.close_panel()
	inventory_ui.bag_button.disabled = false
	outside_return_position = Vector2(435, 1404)
	_set_room_state("barn")
	player.position = FarmBarnInterior.SPAWN
	player.facing = Vector2.UP
	ui.show_message("Entered the Barn. Check the ledger, feed trough, animals and product crate.")

func _set_room_state(room: String) -> void:
	if room != "barn":
		if barn_interior:
			barn_interior.visible = false
		if animals:
			animals.set_active(false)
		super._set_room_state(room)
		return

	interiors.active_room = "barn"
	interiors.visible = false
	barn_interior.visible = true
	farm.visible = false
	storage_chest.visible = false
	ambient_fx.visible = false
	focus_overlay.visible = false
	_set_farm_collision_enabled(false)
	player.set_world_bounds(FarmBarnInterior.ROOM_SIZE, 1.04)
	animals.set_active(true)

func _open_animal_panel() -> void:
	inventory_ui.close_panel()
	inventory_ui.bag_button.disabled = true
	animal_panel.open_panel(animals.summary_text())
	player.set_controls_locked(true)

func _on_animal_panel_state_changed(open: bool) -> void:
	if not inventory_ui:
		return
	inventory_ui.bag_button.disabled = open or ui.shop_open
	if not ui.shop_open and not inventory_ui.is_open:
		player.set_controls_locked(open)
	if not open:
		player.set_virtual_move(Vector2.ZERO)

func _on_buy_animal_requested(kind: String) -> void:
	if not animals.can_buy(kind):
		ui.show_message("The barn is full. Maximum animals: %d." % FarmAnimalSystem.MAX_ANIMALS)
		animal_panel.refresh(animals.summary_text())
		return
	var price := animals.price_for(kind)
	if money < price:
		ui.show_message("Not enough gold. %s costs %dg." % [kind.capitalize(), price])
		return
	money -= price
	var animal := animals.buy_animal(kind)
	if animal.is_empty():
		return
	ui.show_message("Welcome %s! Remember to feed and pet your new %s." % [String(animal.get("name","Animal")), kind])
	animal_panel.refresh(animals.summary_text())
	_update_ui()

func _on_buy_feed_requested() -> void:
	if money < FarmAnimalSystem.FEED_BUNDLE_PRICE:
		ui.show_message("Not enough gold for feed. Bundle price: %dg." % FarmAnimalSystem.FEED_BUNDLE_PRICE)
		return
	money -= FarmAnimalSystem.FEED_BUNDLE_PRICE
	animals.buy_feed_bundle()
	ui.show_message("Bought %d animal feed. Feed stock: %d." % [FarmAnimalSystem.FEED_BUNDLE_AMOUNT, animals.feed_stock])
	animal_panel.refresh(animals.summary_text())
	_update_ui()

func _pet_animal() -> void:
	var result := animals.pet_near(player.position)
	if result.is_empty():
		return
	var animal_name := String(result.get("name", "Animal"))
	if bool(result.get("already", false)):
		ui.show_message("%s has already been petted today." % animal_name)
	else:
		ui.show_message("You pet %s. Happiness: %d%%." % [animal_name, int(result.get("happiness", 50))])

func _collect_animal_products() -> void:
	var products := animals.collect_products()
	var eggs := int(products.get("eggs", 0))
	var milk := int(products.get("milk", 0))
	if eggs <= 0 and milk <= 0:
		ui.show_message("No animal products are ready yet. Feed your animals and sleep until tomorrow.")
		return
	produce_inventory["egg"] = int(produce_inventory.get("egg",0)) + eggs
	produce_inventory["milk"] = int(produce_inventory.get("milk",0)) + milk
	inventory_ui.refresh_data(_bag_snapshot(), storage_inventory)
	ui.show_message("Collected %d egg%s and %d milk." % [eggs, "" if eggs == 1 else "s", milk])
	_update_ui()

func _start_next_day(from_midnight: bool) -> void:
	var produced := animals.next_day()
	super._start_next_day(from_midnight)
	var eggs := int(produced.get("eggs",0))
	var milk := int(produced.get("milk",0))
	if eggs > 0 or milk > 0:
		ui.show_message("Morning farm report: %d egg%s and %d milk are waiting in the Barn product crate." % [eggs, "" if eggs == 1 else "s", milk])

func _bag_snapshot() -> Dictionary:
	var bag := super._bag_snapshot()
	bag["egg"] = int(produce_inventory.get("egg",0))
	bag["milk"] = int(produce_inventory.get("milk",0))
	return bag

func _bag_item_count(item_key: String) -> int:
	if item_key == "egg":
		return int(produce_inventory.get("egg",0))
	if item_key == "milk":
		return int(produce_inventory.get("milk",0))
	return super._bag_item_count(item_key)

func _set_bag_item_count(item_key: String, value: int) -> void:
	if item_key == "egg":
		produce_inventory["egg"] = maxi(0,value)
		return
	if item_key == "milk":
		produce_inventory["milk"] = maxi(0,value)
		return
	super._set_bag_item_count(item_key,value)

func save_game() -> void:
	super.save_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	parsed["save_version"] = 8
	parsed["animal_state"] = animals.get_save_data()
	parsed["room"] = interiors.active_room
	parsed["player_x"] = player.position.x
	parsed["player_y"] = player.position.y
	var out := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(parsed))
		ui.show_message("Game saved with barn animals and products.")

func load_game() -> void:
	super.load_game()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	animals.load_save_data(parsed.get("animal_state", {}))

	# Ensure older saves gain the v0.8 inventory keys.
	produce_inventory["egg"] = int(produce_inventory.get("egg",0))
	produce_inventory["milk"] = int(produce_inventory.get("milk",0))
	shipping_pending["egg"] = int(shipping_pending.get("egg",0))
	shipping_pending["milk"] = int(shipping_pending.get("milk",0))
	storage_inventory["egg"] = int(storage_inventory.get("egg",0))
	storage_inventory["milk"] = int(storage_inventory.get("milk",0))
	sell_prices["egg"] = 80
	sell_prices["milk"] = 180

	var saved_room := String(parsed.get("room","outside"))
	if saved_room == "barn":
		_set_room_state("barn")
		player.position = Vector2(float(parsed.get("player_x",FarmBarnInterior.SPAWN.x)),float(parsed.get("player_y",FarmBarnInterior.SPAWN.y)))
	else:
		animals.set_active(false)
	inventory_ui.refresh_data(_bag_snapshot(),storage_inventory)
	if animal_panel:
		animal_panel.refresh(animals.summary_text())
	ui.show_message("Game loaded. Animals, feed and barn progress restored.")
	_update_ui()
