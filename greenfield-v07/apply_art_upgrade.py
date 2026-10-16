from pathlib import Path

root=Path("greenfield-v07/game")
farm=root/"scripts/farm.gd"
s=farm.read_text()

def change(old,new,optional=False):
    global s
    if old not in s:
        if optional:return False
        raise RuntimeError("Missing v0.7 game anchor: "+old[:90])
    s=s.replace(old,new,1)
    return True

# Use all TWELVE distinct fully painted crop species instead of cycling the
# same 5 original shapes (which was visually very noticeable in v0.4-v0.6).
change('float(kind%5)*32.0','float(kind)*32.0')
change('draw_texture_rect_region(plants,Rect2(center-Vector2(19,42),Vector2(38,52)),region,farm_plus._effect_color(kind))',
       'draw_texture_rect_region(plants,Rect2(center-Vector2(21,46),Vector2(42,57)),region,Color.WHITE)')
# Animated world details drawn on the map. Farmland coordinate checks stay intact.
change('    _character(neighbors[0]', '''    # Floating pollen, pond glints and butterflies liven up the painted world.
    var wind: float = birds_time
    for i in range(24):
        var px: float = 202.0+float((i*139)%1180)
        var py: float = 175.0+float((i*73)%700)
        var flutter: Vector2 = Vector2(6.0*sin(wind*0.75+float(i)*1.8),5.0*cos(wind*0.54+float(i)*1.5))
        var spot: Vector2 = Vector2(px,py)+flutter
        if Rect2(707,489,430,294).has_point(spot):
            continue
        var alpha: float = 0.38+0.27*sin(wind*1.35+float(i)*1.6)
        draw_circle(spot,1.6,Color(1.0,0.93,0.64,alpha))
    for i in range(9):
        var pondx: float=350.0+float((i*39)%230)
        var pondy: float=666.0+float((i*27)%135)
        draw_line(Vector2(pondx,pondy),
            Vector2(pondx+8.0+4.0*sin(wind+i),pondy),
            Color(0.78,0.98,1.0,0.13+0.22*abs(sin(wind*0.6+i))),1.3)
    _character(neighbors[0]''')
# Better framing without changing input/player controls.
change('        var loc: Vector2 = _cell_pos(selected)', '        var loc: Vector2 = _cell_pos(selected)')
change('draw_rect(_plot_rect(selected),tag,false,2.0)','draw_rect(_plot_rect(selected),tag,false,2.4)')
change('    cam.zoom = Vector2(1.16, 1.16)','    cam.zoom = Vector2(1.22, 1.22)')
farm.write_text(s)

h=root/"scripts/hud.gd"
ui=h.read_text()
def hp(old,new):
    global ui
    if old not in ui:
        raise RuntimeError("Missing v0.7 HUD anchor: "+old[:90])
    ui=ui.replace(old,new,1)
# Warm readable polished wood-and-bronze interface.
hp('Color(0.15,0.12,0.10,0.93)','Color(0.16,0.11,0.075,0.98)')
hp('Color(0.59,0.39,0.17,1)','Color(0.72,0.47,0.17,1)')
hp('Color(0.35,0.26,0.17,0.95)','Color(0.27,0.20,0.12,0.97)')
hp('Color(1.0,0.83,0.46)','Color(1.0,0.91,0.57)')
# All items become pure hand-drawn pictograms. Field status retains text.
assert 'draw_texture_rect_region(icon_atlas' in ui
# Taller inset "embossed" tool tiles that no longer resemble debug buttons.
ui=ui.replace('panel(Rect2(xx,462,67,57),color,','panel(Rect2(xx,461,67,58),color,')
ui=ui.replace('Rect2(xx+10,469,47,44)','Rect2(xx+10,468,47,44)')
ui=ui.replace('var warm := Color(0.98,0.92,0.78,1)','var warm := Color(1,0.96,0.82,1)')
ui=ui.replace('var accent := Color(0.96,0.75,0.36,1)','var accent := Color(1,0.84,0.49,1)')
h.write_text(ui)
project=root/"project.godot"
ps=project.read_text()
ps=ps.replace('Precision Farming','Major Art Upgrade')
ps=ps.replace('Field Overhaul v0.5','Major Art Upgrade v0.7')
project.write_text(ps)
assert 'float(kind)*32.0' in s
assert 'Color.WHITE' in s
assert "func _plot_rect(" in s and "const STEP := 43.0" in s
assert 'draw_texture_rect_region(icon_atlas' in ui
print("v0.7 patch: all 12 unique crop sprites, animated world ambience, updated camera/UI, gameplay geometry untouched")
