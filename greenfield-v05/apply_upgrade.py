from pathlib import Path
from PIL import Image, ImageDraw
import random

root=Path("greenfield-v05/game")
farm=root/"scripts/farm.gd"
hud=root/"scripts/hud.gd"
assets=root/"art"
assets.mkdir(exist_ok=True,parents=True)

def edit_once(s,old,new):
    if old not in s:
        raise RuntimeError("Patch anchor missing: "+old[:100])
    return s.replace(old,new,1)

s=farm.read_text(encoding="utf-8")
s=edit_once(s,'const FARM_START := Vector2(749, 526)','const FARM_START := Vector2(749, 525)')
s=edit_once(s,'const STEP := 34.0','const STEP := 48.0')
s=edit_once(s,'const COLS := 11','const COLS := 9')
s=edit_once(s,'const ROWS := 7','const ROWS := 6')
s=edit_once(s,'var land: Texture2D','var soil_atlas: Texture2D\nvar plot_particles: Array = []\nvar land: Texture2D')
s=edit_once(s,'    land = load("res://art/meadow.webp")','    soil_atlas = load("res://art/farm_soil.png")\n    land = load("res://art/meadow.webp")')
s=edit_once(s,'    cam.zoom = Vector2(1.05, 1.05)','    cam.zoom = Vector2(1.16, 1.16)')
s=edit_once(s,'    cam.global_position = position_farmer\n\nfunc _physics_process',"""    cam.global_position = position_farmer
    _migrate_extra_plots()

func _physics_process""")
s=edit_once(s,'    floating = floating.filter(func(f): return f["ttl"] > 0.0)',"""    floating = floating.filter(func(f): return f["ttl"] > 0.0)
    for p in plot_particles:
        p["ttl"] = float(p["ttl"]) - delta
        p["pos"] = Vector2(p["pos"]) + Vector2(p["velocity"]) * delta
    plot_particles = plot_particles.filter(func(p): return float(p["ttl"])>0.0)""")
s=edit_once(s,'''        if info.get("tilled",false):
            draw_rect(Rect2(center-Vector2(14,9),Vector2(28,19)),Color(0.23,0.12,0.075,0.2))
        if info.get("watered",false):
            draw_rect(Rect2(center-Vector2(13,7),Vector2(26,14)),Color(0.12,0.32,0.57,0.16))''', '''        if info.get("tilled",false):
            var variation: int = (1 if info.get("watered",false) else 0) + (2 if int(info.get("fert",0))>0 else 0)
            var area := Rect2(center-Vector2(23,22),Vector2(46,44))
            draw_texture_rect_region(soil_atlas,area,Rect2(float(variation*48),0,48,48))''')
s=edit_once(s,'draw_texture_rect_region(plants,Rect2(center-Vector2(20,39),Vector2(40,50)),region,farm_plus._effect_color(kind))','draw_texture_rect_region(plants,Rect2(center-Vector2(23,47),Vector2(46,60)),region,farm_plus._effect_color(kind))')
s=edit_once(s,'    farm_plus.draw_world()\n    _character(neighbors[0]', '''    farm_plus.draw_world()
    var selected: Vector2i = _choose_plot()
    if _inside(selected):
        var loc: Vector2 = _cell_pos(selected)
        var state: Dictionary = plots.get(selected,{})
        var tag: Color = _target_color(selected)
        draw_rect(Rect2(loc-Vector2(24,23),Vector2(48,46)),Color(tag.r,tag.g,tag.b,0.13),true)
        draw_rect(Rect2(loc-Vector2(24,23),Vector2(48,46)),tag,false,3.0)
        for sx in [-1.0,1.0]:
            for sy in [-1.0,1.0]:
                var corner: Vector2=loc+Vector2(23.0*sx,22.0*sy)
                draw_line(corner,corner-Vector2(10.0*sx,0),Color(1,1,0.85),2.2)
                draw_line(corner,corner-Vector2(0,10.0*sy),Color(1,1,0.85),2.2)
        if int(state.get("crop",-1))>=0 and int(state.get("age",0))>=DAYS[int(state["crop"])]:
            draw_circle(loc+Vector2(0,-49),7,Color(1,0.82,0.25,0.84))
    for particle in plot_particles:
        var fp: Vector2=particle["pos"]
        draw_circle(fp,float(particle["size"])*clampf(float(particle["ttl"]),0.1,1.0),particle["color"])
    _character(neighbors[0]''')
start=s.index('func _choose_plot() -> Vector2i:')
end=s.index('\nfunc _do_action',start)
s=s[:start]+'''func _choose_plot() -> Vector2i:
    # Target the square in front of the farmer, not an arbitrary nearby plot.
    var forward: Vector2 = [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][face]
    var probe: Vector2 = position_farmer+forward*57.0
    var cell: Vector2i = _nearest_cell(probe)
    if _inside(cell) and position_farmer.distance_to(_cell_pos(cell))<=110.0:
        return cell
    var underfoot: Vector2i = _nearest_cell(position_farmer)
    if _inside(underfoot) and position_farmer.distance_to(_cell_pos(underfoot))<=58.0:
        return underfoot
    return Vector2i(-1,-1)

func _target_color(cell: Vector2i) -> Color:
    var state: Dictionary = plots.get(cell,{})
    var crop: int = int(state.get("crop",-1))
    if crop>=0 and int(state.get("age",0))>=farm_plus._grow_time(crop,int(state.get("fert",0)),int(state.get("regrow",0))>0):
        return Color(1.0,0.78,0.18) # gold = ready to harvest
    if crop>=0 and not bool(state.get("watered",false)):
        return Color(0.27,0.71,1.0) # blue = thirsty
    if bool(state.get("tilled",false)) and crop<0:
        return Color(0.34,0.98,0.57) # green = plantable
    return Color(1.0,0.93,0.38) # yellow = target

func _target_message(cell: Vector2i) -> String:
    var state: Dictionary = plots.get(cell,{})
    var crop: int = int(state.get("crop",-1))
    if crop>=0:
        var ready: bool = int(state.get("age",0))>=farm_plus._grow_time(crop,int(state.get("fert",0)),int(state.get("regrow",0))>0)
        if ready: return "READY TO HARVEST"
        if not bool(state.get("watered",false)): return "NEEDS WATER"
        return "GROWING: "+CROPS[crop]
    if not bool(state.get("tilled",false)): return "TILL THIS SOIL"
    if chosen==2 and not bool(state.get("watered",false)): return "WATER THIS PLOT"
    return "READY TO PLANT"

func _migrate_extra_plots() -> void:
    # Move edge plots from the original 11x7 grid into the new spacious 9x6 field.
    var extras: Array=[]
    for c in plots.keys():
        if not _inside(c): extras.append(c)
    for c in extras:
        var info: Dictionary = plots[c]
        plots.erase(c)
        var destination := Vector2i(-1,-1)
        for yy in range(ROWS):
            for xx in range(COLS):
                var candidate := Vector2i(xx,yy)
                if not plots.has(candidate) and destination.x<0:
                    destination=candidate
        if destination.x>=0:
            plots[destination]=info

func _plot_fx(cell: Vector2i, method: int) -> void:
    var pos: Vector2 = _cell_pos(cell)
    var shade: Color = Color(0.59,0.85,1.0) if method==2 else (Color(0.81,0.99,0.39) if method==1 else Color(1.0,0.78,0.35))
    for i in range(10):
        var angle: float=float(i)*TAU/10.0+float(rng.randf())*0.3
        plot_particles.append({"pos":pos+Vector2(rng.randf_range(-12,12),rng.randf_range(-5,5)),
            "velocity":Vector2(cos(angle)*rng.randf_range(16,46),-abs(sin(angle))*rng.randf_range(22,54)),
            "ttl":rng.randf_range(0.35,0.8),"size":rng.randf_range(2.0,4.0),"color":shade})
''' + s[end:]
s=edit_once(s,'''    if chosen < 4:
        farm_plus.act(cell)
        return''','''    if chosen < 4:
        if cell.x<0: cell=_choose_plot()
        var nearby: bool = _inside(cell) and position_farmer.distance_to(_cell_pos(cell))<=112.0
        if not nearby:
            _tell("Move beside the plot. The highlighted tile is your target.")
            return
        var previous: Dictionary=plots.get(cell,{})
        var old_crop: int=int(previous.get("crop",-1))
        var old_wet: bool=bool(previous.get("watered",false))
        farm_plus.act(cell)
        var current: Dictionary=plots.get(cell,{})
        if chosen==2 and not old_wet and bool(current.get("watered",false)):
            _plot_fx(cell,2)
        elif chosen==1 and old_crop<0 and int(current.get("crop",-1))>=0:
            _plot_fx(cell,1)
        elif chosen==3 and old_crop>=0:
            _plot_fx(cell,3)
        elif chosen==0 and not bool(previous.get("tilled",false)) and bool(current.get("tilled",false)):
            _plot_fx(cell,0)
        return''')
s=edit_once(s,'''if _inside(cell) and position_farmer.distance_to(worldp) < 180:''','''if _inside(cell) and worldp.distance_to(_cell_pos(cell))<STEP*0.72 and position_farmer.distance_to(_cell_pos(cell))<112.0:''')
s=edit_once(s,'''    elif p.y>size.y*0.58 and p.x>size.x*0.84:
        _talk() if chosen==6 else _do_action()''','''    elif p.y>size.y*0.58 and p.x>size.x*0.84:
        _talk() if chosen==6 else _do_action(_choose_plot())''')
farm.write_text(s,encoding="utf-8")

h=hud.read_text(encoding="utf-8")
h=edit_once(h,'var font: Font','var icon_atlas: Texture2D\nvar font: Font')
h=edit_once(h,'    font = ThemeDB.fallback_font','    icon_atlas = load("res://art/tool_icons.png")\n    font = ThemeDB.fallback_font')
h=edit_once(h,'''    # Thumb-friendly 8 item toolbelt and active highlighting.''','''    var active_plot: Vector2i=world._choose_plot()
    if active_plot.x>=0:
        var state_col: Color=world._target_color(active_plot)
        panel(Rect2(306,83,352,41),Color(0.10,0.17,0.13,0.90),state_col)
        label("PLOT %d,%d   %s" % [active_plot.x+1,active_plot.y+1,world._target_message(active_plot)],319,110,15,state_col)
    # Pixel-art icon toolbelt with no tool-name abbreviations.''')
h=edit_once(h,'''        label(ICONS[i],xx+24,489,26,Color(1,0.94,0.75))
        label(TITLES[i],xx+4,510,10)''','''        draw_texture_rect_region(icon_atlas,Rect2(xx+10,469,47,44),Rect2(float(i)*48.0,0,48,48))''')
hud.write_text(h,encoding="utf-8")

# Pixel-designed tool icons (8 tools x 48), not fonts or placeholder letters.
sheet=Image.new("RGBA",(48*8,48),(0,0,0,0))
for idx in range(8):
    im=Image.new("RGBA",(24,24),(0,0,0,0))
    d=ImageDraw.Draw(im)
    wood="#996034"; edge="#342719"; metal="#ced9d8"; metal2="#7d9697"
    def line(ps,fill,width=2): d.line(ps,fill=fill,width=width,joint="curve")
    if idx==0: # hoe
        line([(7,21),(16,6)],wood,3);line([(14,6),(21,8),(20,12),(13,10)],metal,3)
        d.rectangle((14,6,21,8),fill=metal2)
    elif idx==1: # seed pouch
        d.polygon([(6,11),(10,7),(16,7),(19,12),(18,21),(6,21)],fill="#c08b43",outline=edge)
        d.rectangle((8,6,16,9),fill="#6b4c33")
        for xx,yy in [(10,12),(15,14),(12,17)]:d.ellipse((xx,yy,xx+3,yy+4),fill="#eacc72")
    elif idx==2: # watering can
        d.polygon([(5,10),(17,10),(18,20),(7,20)],fill="#54b6be",outline="#1e5e6e")
        d.arc((13,4,22,16),180,350,fill=metal,width=3)
        line([(16,12),(22,9)],"#8ac8d1",3); d.rectangle((2,6,7,9),fill="#38636d")
        for x,y in [(21,16),(19,20)]:d.ellipse((x,y,x+2,y+3),fill="#75bdeb")
    elif idx==3: # sickle
        line([(7,22),(12,12)],wood,3);d.arc((7,2,23,19),35,270,fill=metal,width=4)
        d.arc((10,4,21,16),35,250,fill=metal2,width=2)
    elif idx==4: # axe
        line([(7,22),(14,4)],wood,3);d.polygon([(12,5),(21,3),(22,12),(13,11)],fill=metal,outline=metal2)
    elif idx==5: # fishing rod/fish
        line([(5,22),(16,3)],wood,2);d.arc((10,4,20,15),270,365,fill="#d3e0cf",width=2)
        d.ellipse((13,16,21,21),fill="#86b2ce",outline="#28516e")
        d.polygon([(13,18),(9,16),(9,22)],fill="#6b9cb3")
        d.point((19,18),fill="#143d4d")
    elif idx==6: # shop basket
        d.rectangle((4,10,21,21),fill="#b87935",outline=edge,width=2)
        for xx in [8,13,18]:line([(xx,11),(xx,20)],"#e1b871",1)
        d.arc((8,3,17,14),190,345,fill="#e9cb83",width=2)
        d.ellipse((10,4,15,8),fill="#f9d464")
    else: # sleep moon/stars
        d.ellipse((5,3,20,18),fill="#f7e6a6")
        d.ellipse((10,0,23,13),fill=(0,0,0,0))
        d.polygon([(19,17),(20,20),(23,21),(20,22),(19,24),(17,21),(14,20),(17,19)],fill="#e4be67")
    sheet.paste(im.resize((48,48),Image.Resampling.NEAREST),(idx*48,0))
sheet.save(assets/"tool_icons.png")

# Painted large tilled / irrigated / fertilized farm plots: 4 textured variants.
tile_sheet=Image.new("RGBA",(192,48),(0,0,0,0))
for idx in range(4):
    rng=random.Random(120+idx)
    wet=idx%2==1
    fert=idx>=2
    im=Image.new("RGBA",(48,48),(0,0,0,0))
    d=ImageDraw.Draw(im)
    rim="#4a2a1b" if not wet else "#263b42"
    earth="#895239" if not wet else "#4c625a"
    d.rounded_rectangle((1,3,46,46),radius=8,fill=rim,outline="#b8854b" if not wet else "#5d8e8b",width=2)
    d.rounded_rectangle((4,6,43,43),radius=6,fill=earth)
    for xx in [10,21,32]:
        line_points=[(xx-2,8),(xx+1,15),(xx-1,25),(xx+2,37)]
        d.line(line_points,fill="#ab7150" if not wet else "#537c77",width=4)
        d.line([(xx+3,10),(xx+4,38)],fill="#552f21" if not wet else "#36525a",width=2)
    for _ in range(30):
        x=rng.randrange(5,44);y=rng.randrange(8,42)
        col=rng.choice(["#ba8960","#6c402d","#d5a26a"] if not wet else ["#618882","#385962","#8daaa2"])
        d.rectangle((x,y,x+rng.randrange(1,3),y+1),fill=col)
    if wet:
        for x,y in [(10,12),(28,17),(34,34),(16,37)]:
            d.line([(x,y),(x+5,y)],fill="#b3d6d3",width=2)
    if fert:
        for x,y in [(9,32),(25,11),(37,23),(19,30)]:
            d.ellipse((x,y,x+3,y+3),fill="#f3cd77")
    tile_sheet.paste(im,(idx*48,0))
tile_sheet.save(assets/"farm_soil.png")
project=root/"project.godot"
txt=project.read_text()
txt=txt.replace("Art Edition","Field Overhaul v0.5")
project.write_text(txt)
assert "var selected: Vector2i = _choose_plot()" in s
assert (assets/"tool_icons.png").stat().st_size>1000
assert (assets/"farm_soil.png").stat().st_size>1000
print("FIELD OVERHAUL v0.5 built: 48-unit textured plots, accurate facing, context labels, icon toolbelt.")
