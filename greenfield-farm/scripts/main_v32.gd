extends "res://scripts/main_v31.gd"

# v3.2 restores the detailed watercolor farmer used in v2.9/v3.0 and keeps
# the readable leg motion by adding a lower-body stride deformation at runtime.
# It also makes hoe targeting friendlier when the tile directly in front is
# already tilled.

var v32_walk_material: ShaderMaterial
var v32_walk_sequence: Array[int] = [1, 2, 3, 2]

func _ready() -> void:
	super()
	_ensure_v32_walk_material()
	_apply_v32_farmer()
	ui.show_message("v3.2: detailed watercolor farmer restored with visible leg stride; hoe targeting now snaps to nearby fresh soil.")

func _apply_v18_farmer() -> void:
	_apply_v32_farmer()
func _apply_v19_farmer() -> void:
	_apply_v32_farmer()
func _apply_v22_farmer() -> void:
	_apply_v32_farmer()
func _apply_v23_farmer() -> void:
	_apply_v32_farmer()
func _apply_v24_farmer() -> void:
	_apply_v32_farmer()
func _apply_v28_farmer() -> void:
	_apply_v32_farmer()
func _apply_v29_farmer() -> void:
	_apply_v32_farmer()
func _apply_v30_farmer() -> void:
	_apply_v32_farmer()
func _apply_v31_farmer() -> void:
	_apply_v32_farmer()

func _apply_v24_walk_timing() -> void:
	_apply_v32_walk_timing()
func _apply_v28_walk_timing() -> void:
	_apply_v32_walk_timing()
func _apply_v29_walk_timing() -> void:
	_apply_v32_walk_timing()
func _apply_v30_walk_timing() -> void:
	_apply_v32_walk_timing()
func _apply_v31_walk_timing() -> void:
	_apply_v32_walk_timing()

func _ensure_v32_walk_material() -> void:
	if v32_walk_material:
		return
	var walk_shader := Shader.new()
	walk_shader.code = """
shader_type canvas_item;

uniform float walking = 0.0;
uniform float stride = 0.0;
uniform float side_view = 0.0;

void fragment() {
	vec2 frame_count = vec2(4.0, 4.0);
	vec2 frame_origin = floor(UV * frame_count) / frame_count;
	vec2 local_uv = fract(UV * frame_count);

	if (walking > 0.5 && local_uv.y > 0.52) {
		float lower = smoothstep(0.52, 0.95, local_uv.y);
		float foot = smoothstep(0.68, 0.98, local_uv.y);
		float leg_side = local_uv.x < 0.5 ? -1.0 : 1.0;

		vec2 delta = vec2(0.0);
		if (side_view > 0.5) {
			delta.x = leg_side * stride * 0.034 * lower;
			delta.y = leg_side * stride * 0.028 * foot;
		} else {
			delta.x = leg_side * stride * 0.060 * lower;
			delta.y = -abs(stride) * 0.012 * foot;
		}

		local_uv = clamp(local_uv + delta, vec2(0.015), vec2(0.985));
	}

	vec2 sample_uv = frame_origin + local_uv / frame_count;
	COLOR = texture(TEXTURE, sample_uv) * COLOR;
}
"""
	v32_walk_material = ShaderMaterial.new()
	v32_walk_material.shader = walk_shader

func _apply_v32_farmer() -> void:
	if not player:
		return
	var tex: Texture2D = _load_v24_farmer_texture()
	if not tex:
		return
	if player.custom_character_sheet != tex:
		player.set_custom_character_sheet(tex, 4, 4, Vector2(3.15, 3.15))
	_ensure_v32_walk_material()
	if player.character_sprite:
		player.character_sprite.material = v32_walk_material
		player.character_sprite.modulate = Color.WHITE
		player.character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _apply_v32_walk_timing() -> void:
	if not player or not player.character_sprite:
		return
	_apply_v32_farmer()

	var row := 0
	var side_view := false
	if absf(player.facing.x) > absf(player.facing.y):
		row = 1 if player.facing.x > 0.0 else 2
		side_view = true
	else:
		row = 0 if player.facing.y >= 0.0 else 3

	var visual_walk := player.is_walk_visual_active()
	if not visual_walk:
		player.character_sprite.frame_coords = Vector2i(0, row)
		player.character_sprite.position = Vector2(0, -20)
		if v32_walk_material:
			v32_walk_material.set_shader_parameter("walking", 0.0)
			v32_walk_material.set_shader_parameter("stride", 0.0)
			v32_walk_material.set_shader_parameter("side_view", 1.0 if side_view else 0.0)
		return

	var phase: int = int(floor(player.walk_time * 0.80)) % v32_walk_sequence.size()
	player.character_sprite.frame_coords = Vector2i(v32_walk_sequence[phase], row)

	# walk_time advances at 8 units/sec. This gives roughly three complete steps
	# per second while preserving v3.0's short visual hold after joystick release.
	var stride := sin(player.walk_time * PI * 0.75)
	if v32_walk_material:
		v32_walk_material.set_shader_parameter("walking", 1.0)
		v32_walk_material.set_shader_parameter("stride", stride)
		v32_walk_material.set_shader_parameter("side_view", 1.0 if side_view else 0.0)
	player.character_sprite.position = Vector2(0, -20.8 - absf(stride) * 0.8)

func _on_player_action(target_position: Vector2) -> void:
	# Keep all inherited interactions intact. Only make the hoe forgiving when
	# the exact target is already worked soil, which was producing repeated
	# generic failure messages in the phone recording.
	if selected_tool == 0 and interiors.active_room == "outside" and _get_near_interaction().is_empty():
		var target_cell := farm.world_to_cell(target_position)
		if farm.is_valid_cell(target_cell):
			var target_data: Dictionary = farm.get_cell(target_cell)
			if bool(target_data.get("tilled", false)):
				var nearby := _find_v32_fresh_hoe_cell(target_cell)
				if nearby.x >= 0:
					super._on_player_action(farm.cell_to_world(nearby))
					return
				ui.show_message("This patch is already tilled. Move toward fresh grass.")
				return
	super._on_player_action(target_position)

func _find_v32_fresh_hoe_cell(origin_cell: Vector2i) -> Vector2i:
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
	]
	var best := Vector2i(-1, -1)
	var best_distance := 999999.0
	for offset in offsets:
		var cell := origin_cell + offset
		if not farm.is_valid_cell(cell):
			continue
		var world_pos := farm.cell_to_world(cell)
		var distance := world_pos.distance_to(player.position)
		if distance > 118.0:
			continue
		var data: Dictionary = farm.get_cell(cell)
		if bool(data.get("tilled", false)):
			continue
		if distance < best_distance:
			best_distance = distance
			best = cell
	return best
