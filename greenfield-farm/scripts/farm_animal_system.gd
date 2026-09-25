extends Node2D
class_name FarmAnimalSystem

const MAX_ANIMALS := 8
const CHICKEN_PRICE := 500
const COW_PRICE := 1500
const FEED_BUNDLE_PRICE := 120
const FEED_BUNDLE_AMOUNT := 5

var animals: Array = []
var feed_stock := 3
var egg_stock := 0
var milk_stock := 0
var active := false
var anim_time := 0.0
var next_id := 1

func _ready() -> void:
	z_index = 2
	visible = false

func _process(delta: float) -> void:
	anim_time += delta
	visible = active
	if active:
		queue_redraw()

func set_active(value: bool) -> void:
	active = value
	visible = value
	queue_redraw()

func can_buy(kind: String) -> bool:
	return animals.size() < MAX_ANIMALS and (kind == "chicken" or kind == "cow")

func price_for(kind: String) -> int:
	return CHICKEN_PRICE if kind == "chicken" else COW_PRICE

func buy_animal(kind: String) -> Dictionary:
	if not can_buy(kind):
		return {}
	var name_prefix := "Hen" if kind == "chicken" else "Cow"
	var animal := {
		"id": next_id,
		"kind": kind,
		"name": "%s %d" % [name_prefix, next_id],
		"fed": false,
		"petted": false,
		"happiness": 50,
		"product_ready": 0
	}
	next_id += 1
	animals.append(animal)
	queue_redraw()
	return animal

func buy_feed_bundle() -> void:
	feed_stock += FEED_BUNDLE_AMOUNT

func feed_animals() -> Dictionary:
	var fed_count := 0
	for i in range(animals.size()):
		if feed_stock <= 0:
			break
		var animal: Dictionary = animals[i]
		if not bool(animal.get("fed", false)):
			animal["fed"] = true
			animal["happiness"] = mini(100, int(animal.get("happiness",50)) + 2)
			animals[i] = animal
			feed_stock -= 1
			fed_count += 1
	queue_redraw()
	return {"fed": fed_count, "remaining_feed": feed_stock}

func pet_near(pos: Vector2) -> Dictionary:
	var best_index := -1
	var best_distance := 99999.0
	for i in range(animals.size()):
		var p := _animal_position(i)
		var d := pos.distance_to(p)
		if d < 92.0 and d < best_distance:
			best_distance = d
			best_index = i
	if best_index < 0:
		return {}
	var animal: Dictionary = animals[best_index]
	if bool(animal.get("petted", false)):
		return {"already": true, "name": String(animal.get("name","Animal"))}
	animal["petted"] = true
	animal["happiness"] = mini(100, int(animal.get("happiness",50)) + 4)
	animals[best_index] = animal
	queue_redraw()
	return {"already": false, "name": String(animal.get("name","Animal")), "happiness": int(animal.get("happiness",50))}

func get_interaction(pos: Vector2) -> Dictionary:
	if not active:
		return {}
	for i in range(animals.size()):
		if pos.distance_to(_animal_position(i)) < 92.0:
			var animal: Dictionary = animals[i]
			return {"type":"animal", "name":"Pet %s" % String(animal.get("name","Animal")), "index":i}
	return {}

func next_day() -> Dictionary:
	var produced_eggs := 0
	var produced_milk := 0
	for i in range(animals.size()):
		var animal: Dictionary = animals[i]
		var happy := int(animal.get("happiness",50))
		if bool(animal.get("fed",false)):
			happy = mini(100, happy + 3)
			if String(animal.get("kind","")) == "chicken":
				produced_eggs += 1
			else:
				produced_milk += 1
		else:
			happy = maxi(0, happy - 7)
		animal["happiness"] = happy
		animal["fed"] = false
		animal["petted"] = false
		animals[i] = animal
	egg_stock += produced_eggs
	milk_stock += produced_milk
	queue_redraw()
	return {"eggs": produced_eggs, "milk": produced_milk}

func collect_products() -> Dictionary:
	var result := {"eggs": egg_stock, "milk": milk_stock}
	egg_stock = 0
	milk_stock = 0
	return result

func summary_text() -> String:
	var chickens := 0
	var cows := 0
	var fed := 0
	var happiness_total := 0
	for animal in animals:
		var data: Dictionary = animal
		if String(data.get("kind","")) == "chicken":
			chickens += 1
		else:
			cows += 1
		if bool(data.get("fed",false)):
			fed += 1
		happiness_total += int(data.get("happiness",50))
	var avg_happy := 0 if animals.is_empty() else int(round(float(happiness_total) / float(animals.size())))
	return "Animals %d/%d   Hens %d   Cows %d\nFeed %d   Fed today %d   Happiness %d%%\nReady: Eggs %d   Milk %d" % [animals.size(),MAX_ANIMALS,chickens,cows,feed_stock,fed,avg_happy,egg_stock,milk_stock]

func get_save_data() -> Dictionary:
	return {
		"animals": animals,
		"feed_stock": feed_stock,
		"egg_stock": egg_stock,
		"milk_stock": milk_stock,
		"next_id": next_id
	}

func load_save_data(data: Dictionary) -> void:
	animals = data.get("animals", []).duplicate(true)
	feed_stock = int(data.get("feed_stock", 3))
	egg_stock = int(data.get("egg_stock", 0))
	milk_stock = int(data.get("milk_stock", 0))
	next_id = int(data.get("next_id", animals.size() + 1))
	queue_redraw()

func _animal_position(index: int) -> Vector2:
	var animal: Dictionary = animals[index]
	var base_positions := [Vector2(455,330),Vector2(575,355),Vector2(735,330),Vector2(840,365),Vector2(460,500),Vector2(610,490),Vector2(760,505),Vector2(875,485)]
	var base: Vector2 = base_positions[index % base_positions.size()]
	var phase := anim_time * (0.8 + float(index%3)*0.13) + float(index)*1.7
	var radius := 18.0 if String(animal.get("kind","")) == "chicken" else 12.0
	return base + Vector2(cos(phase)*radius, sin(phase*0.8)*radius*0.55)

func _draw() -> void:
	if not active:
		return
	for i in range(animals.size()):
		var animal: Dictionary = animals[i]
		var p := _animal_position(i)
		if String(animal.get("kind","")) == "chicken":
			_draw_chicken(p, animal)
		else:
			_draw_cow(p, animal)

func _draw_chicken(p: Vector2, animal: Dictionary) -> void:
	var bob := absf(sin(anim_time*4.0 + p.x*0.01))*2.0
	p.y -= bob
	_draw_ellipse(p+Vector2(0,18),Vector2(24,8),Color(0,0,0,0.20))
	draw_circle(p,20,Color("#f2e5c9"))
	draw_circle(p+Vector2(14,-12),13,Color("#f6ead2"))
	draw_polygon(PackedVector2Array([p+Vector2(25,-12),p+Vector2(38,-7),p+Vector2(25,-3)]),PackedColorArray([Color("#e6a13e")]))
	draw_circle(p+Vector2(18,-16),3,Color("#33261f"))
	draw_circle(p+Vector2(8,-27),5,Color("#c74f43"))
	draw_line(p+Vector2(-8,18),p+Vector2(-8,29),Color("#d49b43"),3)
	draw_line(p+Vector2(5,18),p+Vector2(5,29),Color("#d49b43"),3)
	_draw_status(p+Vector2(0,-42), animal)

func _draw_cow(p: Vector2, animal: Dictionary) -> void:
	var sway := sin(anim_time*1.8 + p.x*0.01)*2.0
	p.x += sway
	_draw_ellipse(p+Vector2(0,27),Vector2(42,11),Color(0,0,0,0.22))
	draw_rect(Rect2(p-Vector2(38,24),Vector2(76,48)),Color("#eee6d8"),true)
	draw_circle(p+Vector2(43,-4),24,Color("#e9dfd0"))
	draw_circle(p+Vector2(51,-10),4,Color("#30251f"))
	draw_rect(Rect2(p+Vector2(-20,-22),Vector2(22,19)),Color("#6d5448"),true)
	draw_circle(p+Vector2(18,13),13,Color("#6b5146"))
	for lx in [-25,22]:
		draw_rect(Rect2(p+Vector2(lx,22),Vector2(10,30)),Color("#d9cec0"),true)
		draw_rect(Rect2(p+Vector2(lx,46),Vector2(10,7)),Color("#4b3b34"),true)
	draw_line(p+Vector2(-38,-10),p+Vector2(-55,3),Color("#6c5145"),4)
	_draw_status(p+Vector2(0,-48), animal)

func _draw_status(p: Vector2, animal: Dictionary) -> void:
	var happy := int(animal.get("happiness",50))
	var fed := bool(animal.get("fed",false))
	var c := Color("#74c46a") if happy >= 70 else (Color("#e0b85a") if happy >= 40 else Color("#d66a5d"))
	draw_rect(Rect2(p-Vector2(25,4),Vector2(50,8)),Color(0.1,0.08,0.06,0.72),true)
	draw_rect(Rect2(p-Vector2(24,3),Vector2(48.0*float(happy)/100.0,6)),c,true)
	if fed:
		draw_circle(p+Vector2(34,0),6,Color("#80c05d"))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var a := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(a)*radii.x,sin(a)*radii.y))
	draw_colored_polygon(points,color)
