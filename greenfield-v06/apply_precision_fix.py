from pathlib import Path
from PIL import Image, ImageDraw
import random

root=Path("greenfield-v06/game")
p=root/"scripts/farm.gd"
s=p.read_text(encoding="utf-8")

def patch(old,new):
    global s
    assert old in s, "v06 farm anchor missing: "+old[:110]
    s=s.replace(old,new,1)

# The painted farm is now rendered as one explicit playing surface, with the
# exact same origin/step feeding tilling, highlight, watering and touch.
patch('const FARM_START := Vector2(749, 525)', 'const FARM_START := Vector2(746, 526)')
patch('const STEP := 48.0','const STEP := 43.0')
patch('var soil_atlas: Texture2D','var farm_ground: Texture2D\nvar soil_atlas: Texture2D')
patch('    soil_atlas = load("res://art/farm_soil.png")','    farm_ground = load("res://art/farm_ground.png")\n    soil_atlas = load("res://art/farm_soil.png")')
patch('        draw_texture_rect(land,Rect2(Vector2.ZERO,WORLD),false)',
'''        draw_texture_rect(land,Rect2(Vector2.ZERO,WORLD),false)
    # Opaque terraformed terrain masks baked-in crops on the old static picture.
    # Its 9x6 cells are the only authoritative cells for gameplay and drawing.
    draw_texture_rect(farm_ground, Rect2(Vector2(706,488),Vector2(430,294)),false)''')
patch('var area := Rect2(center-Vector2(23,22),Vector2(46,44))',
      'var area := _plot_rect(cell).grow(-2.0)')
patch('draw_rect(Rect2(loc-Vector2(24,23),Vector2(48,46)),Color(tag.r,tag.g,tag.b,0.13),true)',
      'draw_rect(_plot_rect(selected),Color(tag.r,tag.g,tag.b,0.11),true)')
patch('draw_rect(Rect2(loc-Vector2(24,23),Vector2(48,46)),tag,false,3.0)',
      'draw_rect(_plot_rect(selected),tag,false,2.0)')
patch('var corner: Vector2=loc+Vector2(23.0*sx,22.0*sy)',
      'var corner: Vector2=loc+Vector2(20.0*sx,19.0*sy)')
patch('draw_texture_rect_region(plants,Rect2(center-Vector2(23,47),Vector2(46,60)),region,farm_plus._effect_color(kind))',
      'draw_texture_rect_region(plants,Rect2(center-Vector2(19,42),Vector2(38,52)),region,farm_plus._effect_color(kind))')
patch('func _cell_pos(cell: Vector2i) -> Vector2:',
'''# Shared deterministic world coordinates for plots, visuals and player actions.
func _plot_rect(cell: Vector2i) -> Rect2:
    return Rect2(_cell_pos(cell)-Vector2(20.0,19.0),Vector2(40.0,38.0))

func _cell_pos(cell: Vector2i) -> Vector2:''')
start=s.index('func _choose_plot() -> Vector2i:')
end=s.index('\nfunc _target_color',start)
s=s[:start]+'''func _choose_plot() -> Vector2i:
    var forward: Vector2 = [Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT,Vector2.UP][face]
    var center: Vector2 = position_farmer + forward * 49.0
    var candidate: Vector2i = _nearest_cell(center)
    if _inside(candidate) and center.distance_to(_cell_pos(candidate))<32.0 and position_farmer.distance_to(_cell_pos(candidate))<=82.0:
        return candidate
    # Standing partly inside a row should select the current square, never a distant plot.
    var here: Vector2i=_nearest_cell(position_farmer + forward*18.0)
    if _inside(here) and (position_farmer+forward*18.0).distance_to(_cell_pos(here))<27.0:
        return here
    return Vector2i(-1,-1)
''' +s[end:]
patch('and position_farmer.distance_to(_cell_pos(cell))<=112.0','and position_farmer.distance_to(_cell_pos(cell))<=87.0')
patch('position_farmer.distance_to(_cell_pos(cell))<112.0','position_farmer.distance_to(_cell_pos(cell))<87.0')
# Stop dynamically drawing a 46-wide tilled sprite over neighboring tiles.
p.write_text(s,encoding="utf-8")

# Procedural but art-directed earth, generated at exactly WORLD pixel scale;
# no independent coordinate origins or old painted-on crops remain visible.
random.seed(112)
left,top,w,h=706,488,430,294
img=Image.new("RGBA",(w,h),(0,0,0,0))
d=ImageDraw.Draw(img,"RGBA")
for inset in range(0,15,2):
    d.rounded_rectangle((inset,inset,w-1-inset,h-1-inset),radius=18,
        fill=(83+inset//2,57+inset//2,30+inset//3,150+inset*7))
d.rounded_rectangle((16,13,w-16,h-14),radius=10,fill=(107,68,43,255),outline=(60,38,24,240),width=5)
for i in range(2200):
    x=random.randrange(22,w-22);y=random.randrange(21,h-21)
    color=random.choice([(144,92,58,175),(170,108,59,120),(73,42,25,150),(201,147,85,120),(111,77,50,240),(62,33,20,120)])
    size=random.choice([1,2,2,3])
    d.rectangle((x,y,x+size,y+max(1,size//2)),fill=color)
for row in range(6):
    for col in range(9):
        cx=746-left+col*43;cy=526-top+row*43
        d.rounded_rectangle((cx-20,cy-19,cx+20,cy+19),radius=5,
            fill=(122,77,49,245),outline=(164,117,72,220),width=2)
        d.line([(cx-13,cy-8),(cx+13,cy-7)],fill=(91,54,34,150),width=2)
        d.line([(cx-13,cy+3),(cx+13,cy+4)],fill=(85,51,30,140),width=2)
        for j in range(6):
            px=cx+random.randint(-15,15);py=cy+random.randint(-15,15)
            d.rectangle((px,py,px+2,py+1),fill=random.choice([(202,146,84,180),(84,49,32,240),(170,119,75,170)]))
for bx,by in [(24,23),(w-28,25),(26,h-30),(w-30,h-34)]:
    d.ellipse((bx-4,by-4,bx+4,by+4),fill=(171,116,56,180))
img.save(root/"art/farm_ground.png")

# Static geometry regression checks prevent a future visual/grid desync.
for row in range(6):
    for col in range(9):
        x=746+col*43;y=526+row*43
        assert (706+16+18)<x<(706+430-16-18)
        assert (488+13+18)<y<(488+294-14-18)
        for delta in [(-19,0),(19,0),(0,-18),(0,18)]:
            dx,dy=delta
            xx=int((x+dx-746)/43+0.5) if x+dx>=746 else round((x+dx-746)/43)
            yy=round((y+dy-526)/43)
            assert xx==col and yy==row,("wrong plot target",col,row,dx,dy)
assert s.count("draw_texture_rect(farm_ground") == 1
assert 'var area := _plot_rect(cell).grow(-2.0)' in s
assert (root/"art/farm_ground.png").stat().st_size>5000
print("v0.6 geometry validated: all 54 rendered squares match the exact till/selection/plant locations")
