from pathlib import Path
r=Path('greenfield-v04/game')
p=r/'scripts/farm.gd'
s=p.read_text()
rep={
'const CROPS := ["Carrot", "Pumpkin", "Berry", "Turnip", "Flowers"]':'const CROPS := ["Carrot", "Pumpkin", "Berry", "Turnip", "Flowers", "Radish", "Corn", "Tomato", "Melon", "Potato", "Sunflower", "Pepper"]',
'const COSTS := [12, 18, 24, 20, 30]':'const COSTS := [12, 22, 24, 20, 16, 15, 30, 25, 38, 18, 24, 28]',
'const SALES := [33, 54, 69, 48, 73]':'const SALES := [33, 68, 47, 48, 43, 41, 64, 51, 104, 44, 67, 59]',
'const DAYS := [2, 3, 3, 2, 4]':'const DAYS := [3, 6, 4, 3, 5, 4, 7, 5, 8, 4, 6, 5]',
'var land: Texture2D':'var farm_plus\nvar land: Texture2D',
'    _load_state()\n    cam.global_position':'''    farm_plus=load("res://scripts/farming_plus.gd").new(self)
    _load_state()
    var previous_file := FileAccess.open("user://meadowvale_art_v03.save",FileAccess.READ)
    if previous_file != null:
        var stored=JSON.parse_string(previous_file.get_as_text())
        farm_plus.from_dict(stored.get("farming_v04",{}) if stored is Dictionary else {})
    else:
        farm_plus.from_dict({})
    cam.global_position''',
'var stage: int = clampi(int(info["age"]),0,3)':'var stage: int = clampi(int(float(info["age"])/float(maxi(1,DAYS[kind]))*3.0),0,3)',
'var region := Rect2(float(kind)*32.0,float(stage)*40.0,32.0,40.0)':'var region := Rect2(float(kind%5)*32.0,float(stage)*40.0,32.0,40.0)',
'draw_texture_rect_region(plants,Rect2(center-Vector2(20,39),Vector2(40,50)),region)':'draw_texture_rect_region(plants,Rect2(center-Vector2(20,39),Vector2(40,50)),region,farm_plus._effect_color(kind))',
'    _character(neighbors[0]':'    farm_plus.draw_world()\n    _character(neighbors[0]',
'    if not menu.is_empty(): return\n    if chosen == 6:':'    if not menu.is_empty(): return\n    if chosen < 4:\n        farm_plus.act(cell)\n        return\n    if chosen == 6:',
'    rain = rng.randf() < 0.17\n    for cell in plots.keys():\n        var c: Dictionary = plots[cell]\n        if c["watered"] and int(c["crop"])>=0:\n            c["age"] = mini(3,int(c["age"])+1)\n        c["watered"] = false':'    var rain_yesterday: bool=rain\n    rain = rng.randf() < 0.19\n    farm_plus.next_day(rain_yesterday,rain)',
'func _buy(kind: int) -> void:\n    if kind < 0':'func _buy(kind: int) -> void:\n    farm_plus.buy(kind)\n    return\n    if kind < 0',
'        if menu=="shop":\n            var idx := int((p.y - size.y*0.30)/(size.y*0.115))\n            _buy(idx)\n        else:menu=""':'        if menu=="shop":\n            farm_plus.shop_tap(p,size)\n        else:menu=""',
'    var file := FileAccess.open("user://meadowvale_art_v03.save",FileAccess.WRITE)':'    data["farming_v04"]=farm_plus.to_dict()\n    var file := FileAccess.open("user://meadowvale_art_v03.save",FileAccess.WRITE)'
}
for a,b in rep.items():
    assert a in s, f'missing source patch: {a[:60]}'
    s=s.replace(a,b,1)
s=s.replace('seed_kind = (seed_kind+1)%5','seed_kind = (seed_kind+1)%CROPS.size()').replace('seed_kind=(seed_kind+1)%5','seed_kind=(seed_kind+1)%CROPS.size()')
s=s.replace('var worldp := get_global_mouse_position()','var worldp: Vector2 = cam.global_position + (p-size*0.5)/cam.zoom')
p.write_text(s)
h=r/'scripts/hud.gd';s=h.read_text()
s=s.replace('    label("Seeds %d  ·  Fish %d  ·  Wood %d" % [world.seed_count,world.fish,world.wood],370,57,13)','    label("FARM Lv.%d · XP %d · wood %d" % [world.farm_plus.level,world.farm_plus.xp,world.wood],370,57,13)')
s=s.replace('    label("SEED   "+world.CROPS[world.seed_kind]+"  ↻",34,115,14)','    label("SEED "+world.CROPS[world.seed_kind]+" x"+str(world.farm_plus.selected_stock())+" · WATER "+str(world.farm_plus.water)+"/"+str(world.farm_plus.water_max),27,115,12)')
s=s.replace('    if world.menu!="":','    if world.menu=="shop":\n        world.farm_plus.draw_shop(self)\n        draw_set_transform(Vector2.ZERO,0,Vector2.ONE)\n        return\n    if world.menu!="":')
h.write_text(s)
p=r/'project.godot';s=p.read_text().replace('config/name="Greenfield Reborn — Art Edition"','config/name="Greenfield Reborn v0.4 - Farming Plus"');p.write_text(s)
print('Patched v0.4 farm logic, touch targeting and updated HUD.')
