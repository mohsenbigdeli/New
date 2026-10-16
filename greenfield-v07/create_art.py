from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random, math
root=Path("greenfield-v07/game")
art=root/"art"; art.mkdir(parents=True,exist_ok=True)
random.seed(724)

# Fully redesigned farm terrain. The central 9x6 plot lattice is IDENTICAL to
# the v0.6 gameplay lattice: FARM_START=(746,526), STEP=43, 9x6.
W,H=430,294
base=Image.new("RGBA",(W,H))
b=ImageDraw.Draw(base)
for y in range(H):
    f=y/H
    b.line((0,y,W,y), fill=(int(78+11*f),int(109+6*f),int(53+9*f),255))
rng=random.Random(401)
for _ in range(16000):
    x=rng.randrange(W);y=rng.randrange(H)
    r=rng.choice((1,1,1,2,2,3))
    color=rng.choice([(39,87,36,170),(137,169,65,150),(185,170,73,105),(32,76,40,145),(180,144,74,100),(107,140,48,160)])
    b.rectangle((x,y,x+r,y+r),fill=color)
# Worn stone lip at plot perimeter and moss in stones
b.rounded_rectangle((15,13,424,289),radius=20,fill=(57,52,34,255),outline=(197,169,105,255),width=3)
b.rounded_rectangle((19,17,420,285),radius=13,fill=(105,70,42,255),outline=(74,52,34,255),width=3)
for _ in range(2600):
    x=rng.randrange(22,416);y=rng.randrange(19,283)
    r=rng.choice((1,1,2,3))
    b.rectangle((x,y,x+r,y+r//2+1),fill=rng.choice([(145,98,59,200),(86,55,39,255),(190,142,82,130),(69,45,27,255),(177,122,68,130)]))
# 54 unplanted squares. Crops will be real dynamically-drawn sprites.
for row in range(6):
    for col in range(9):
        x=40+col*43; y=38+row*43
        b.rounded_rectangle((x-20,y-19,x+20,y+19),radius=5,fill=(84,53,33,255),outline=(181,129,71,255),width=2)
        b.rounded_rectangle((x-17,y-16,x+17,y+16),radius=3,fill=(119,77,46,255))
        for k in range(4):
            yy=y-10+k*7
            b.line((x-15,yy,x+15,yy+1),fill=(70,45,30,235),width=2)
            b.line((x-13,yy-2,x+11,yy-2),fill=(167,108,63,175),width=1)
        for _ in range(14):
            tx=x+rng.randint(-15,15);ty=y+rng.randint(-14,14)
            b.rectangle((tx,ty,tx+1,ty+1),fill=rng.choice([(191,135,78,255),(218,161,93,255),(60,39,29,255)]))
# Natural mossy tufts and little white flowers outside the field, never over plot hitboxes
for _ in range(180):
    x=rng.randrange(W);y=rng.randrange(H)
    if 18<x<424 and 18<y<285:continue
    b.line((x,y,x-1,y-4),fill=(51,107,37,255),width=1)
    b.line((x,y,x+2,y-5),fill=(140,178,53,255),width=1)
    if rng.random()<0.19:
        b.ellipse((x-2,y-5,x+1,y-2),fill=(255,223,172,255))
base.save(art/"farm_ground.png")

soil=Image.new("RGBA",(48*4,48))
for variant in range(4):
    wet=variant%2==1; fert=variant>=2
    tile=Image.new("RGBA",(48,48),(0,0,0,0))
    d=ImageDraw.Draw(tile)
    d.rounded_rectangle((1,2,46,46),radius=5,fill=(75,51,35,252) if not wet else (43,52,45,252),outline=(190,135,80,255) if not wet else (90,133,133,255),width=2)
    d.rounded_rectangle((4,5,43,43),radius=4,fill=(119,77,47,255) if not wet else (67,82,72,255))
    r=random.Random(variant+970)
    for j in range(4):
        yy=11+j*8
        d.line((7,yy,40,yy+1),fill=(68,42,30,245) if not wet else (37,58,59,245),width=3)
        d.line((10,yy-2,39,yy-2),fill=(180,116,68,180) if not wet else (112,143,133,160),width=2)
    for i in range(55):
        x=r.randint(6,41);y=r.randint(6,40)
        d.rectangle((x,y,x+r.randint(0,1),y+1),fill=r.choice([(196,140,82,255),(88,54,34,255)] if not wet else [(130,165,164,255),(40,65,62,255)]))
    if wet:
        for xx,yy in [(8,11),(26,20),(12,33),(31,38)]:
            d.line((xx,yy,xx+6,yy),fill=(172,203,205,215),width=1)
    if fert:
        for xx,yy in [(15,15),(34,27),(21,39),(38,10)]:
            d.ellipse((xx,yy,xx+2,yy+2),fill=(240,202,113,255))
    soil.paste(tile,(variant*48,0))
soil.save(art/"farm_soil.png")

# Illustrative pixel-painted 12 crop species x four growth stages.
CROP_COUNT=12
sheet=Image.new("RGBA",(CROP_COUNT*32,4*40),(0,0,0,0))
LEAF=[(42,105,43),(58,142,52),(94,181,57),(166,211,77)]
def rr(d,bb,c):d.rectangle(bb,fill=c)
def ellipse(d,box,fill,outline=None,width=1):d.ellipse(box,fill=fill,outline=outline,width=width)
for kind in range(CROP_COUNT):
    for stage in range(4):
        im=Image.new("RGBA",(32,40),(0,0,0,0))
        d=ImageDraw.Draw(im)
        pr=random.Random(1500+kind*19+stage)
        # Soil contact shadow, strong green-to-dark volume with different leaf silhouettes
        ellipse(d,(7,31,26,37),(23,34,20,128))
        ht=[9,16,24,31][stage]; top=35-ht
        base_x=16+(kind%3-1)
        dark=(29,77,37); mid=(48,124,52); light=(127,206,78)
        d.line((base_x,33,base_x,top+3),fill=(35,96,42),width=2 if stage<2 else 3)
        if stage==0:
            ellipse(d,(base_x-6,top+1,base_x,top+5),mid)
            ellipse(d,(base_x,top+1,base_x+6,top+5),light)
            rr(d,(base_x-1,top-1,base_x+1,top+4),mid)
        else:
            leaf_n=3+stage*2
            for j in range(leaf_n):
                yy=32-int((j+1)*ht/(leaf_n+1))
                side=-1 if j%2==0 else 1
                reach=6+(stage*2)+(j%3)
                x=base_x+side*reach
                d.line((base_x,yy+3,x,yy-2),fill=(30,91,40),width=2)
                ellipse(d,(min(base_x,x)-3,yy-5,max(base_x,x)+2,yy+1),dark)
                ellipse(d,(min(base_x,x)-1,yy-6,max(base_x,x),yy-1),LEAF[(j+kind)%4])
            ellipse(d,(base_x-4,top,base_x+4,top+6),mid)
            ellipse(d,(base_x-2,top,base_x+3,top+3),light)
        if stage>=2:
            fruit_count = 1 if stage==2 else (3 if kind in [2,7,11,4] else 2)
            for j in range(fruit_count):
                xx=base_x+int(math.sin(j*2.9+kind)*9)
                yy=30-int(j*6) if stage==3 else 29
                if kind in (0,5,3,9): # root crops; carrots radishes turnips potatoes
                    tone={0:(230,112,37),3:(163,106,194),5:(210,59,87),9:(181,143,86)}[kind]
                    if stage==3:
                        d.polygon([(xx-4,yy-1),(xx+4,yy-1),(xx,yy+7)],fill=(87,51,37))
                    ellipse(d,(xx-4,yy-6,xx+4,yy+3),tone,outline=(86,52,49))
                    d.arc((xx-3,yy-5,xx+2,yy+1),180,315,fill=(253,210,129),width=1)
                elif kind==1: # pumpkins
                    ellipse(d,(xx-7,yy-7,xx+7,yy+5),(225,113,31),outline=(117,68,34))
                    for off in [-3,2]:d.line((xx+off,yy-5,xx+off,yy+3),fill=(245,154,50),width=1)
                    rr(d,(xx,yy-9,xx+2,yy-7),(45,110,45))
                elif kind==2: # berries
                    for ox,oy in [(0,0),(-4,3),(4,2),(2,-3)]:
                        ellipse(d,(xx+ox-2,yy+oy-2,xx+ox+2,yy+oy+2),(111,72,182),outline=(57,48,115))
                        d.point((xx+ox-1,yy+oy-1),fill=(218,187,255))
                elif kind in (4,10): # flowers and sunflowers
                    col=(255,189,202) if kind==4 else (250,208,61)
                    radius=5 if kind==4 else 7
                    for a in range(8):
                        phi=a*math.tau/8
                        xp=int(xx+math.cos(phi)*radius);yp=int(yy+math.sin(phi)*radius)
                        ellipse(d,(xp-2,yp-2,xp+2,yp+2),col,outline=(161,93,53))
                    ellipse(d,(xx-3,yy-3,xx+3,yy+3),(122,72,49) if kind==10 else (236,202,88))
                elif kind==6: # corn
                    ellipse(d,(xx-3,yy-11,xx+3,yy+5),(251,202,56),outline=(146,104,49))
                    for oy in [-6,-1,4]:
                        d.line((xx-2,yy+oy,xx+2,yy+oy),fill=(255,239,119),width=1)
                    d.polygon([(xx-3,yy),(xx-8,yy-8),(xx-6,yy+5)],fill=(65,146,56))
                elif kind in [7,11]: # tomato and pepper
                    col=(232,63,54) if kind==7 else (248,85,50)
                    ellipse(d,(xx-5,yy-5,xx+5,yy+5),col,outline=(125,54,48))
                    d.line((xx,yy-6,xx,yy-2),fill=light,width=2)
                    ellipse(d,(xx-3,yy-3,xx-1,yy-1),(255,170,117))
                elif kind==8: # melon
                    ellipse(d,(xx-7,yy-4,xx+7,yy+4),(70,163,70),outline=(37,89,51))
                    for off in [-3,0,3]:
                        d.line((xx+off,yy-4,xx+off,yy+4),fill=(125,205,77))
        sheet.paste(im,(kind*32,stage*40),im)
sheet.save(art/"crops.png")

# High-contrast original cast with hat, tunic, boots, and individualized palettes.
def character_sheet(skin,tunic,hair,hat,apron=False):
    canvas=Image.new("RGBA",(96,144),(0,0,0,0))
    for direction in range(4):
        for frame in range(4):
            im=Image.new("RGBA",(24,36),(0,0,0,0));d=ImageDraw.Draw(im)
            walk=[0,2,0,-2][frame]
            shadow=(23,39,39);outline=(41,39,40)
            # shoes and legs
            rr(d,(8,29+max(0,walk),11,33+max(0,walk)),(71,49,42))
            rr(d,(13,29+max(0,-walk),16,33+max(0,-walk)),(71,49,42))
            rr(d,(7,32,11,34),(44,43,43))
            rr(d,(13,32,17,34),(44,43,43))
            # dark lined silhouette and colored tunic
            rr(d,(6,15,18,29),outline);rr(d,(8,16,16,26),tunic)
            rr(d,(9,25,12,28),(61,76,103));rr(d,(13,25,16,28),(61,76,103))
            if apron:
                rr(d,(10,20,15,27),(207,189,145))
            rr(d,(8,17,9,25),(246,213,153));rr(d,(16,17,17,25),(246,213,153))
            # arms gesticulate across walk frames
            off=(-1 if frame%2 else 1)
            rr(d,(5,18+off,7,26+off),skin)
            rr(d,(17,18-off,19,26-off),skin)
            # head outline
            rr(d,(7,6,17,17),outline);rr(d,(8,7,16,16),skin)
            if direction==3: # back
                rr(d,(8,6,16,14),hair)
            else:
                rr(d,(8,6,17,10),hair)
                if direction!=1:rr(d,(10,12,11,13),(41,37,36))
                if direction!=2:rr(d,(15,12,16,13),(41,37,36))
                if direction==0:rr(d,(12,15,14,15),(169,92,78))
            # woven straw hat
            d.line((4,7,20,7),fill=(91,61,38),width=3)
            d.line((5,6,19,6),fill=(230,188,98),width=2)
            d.rounded_rectangle((8,1,16,7),radius=2,fill=hat,outline=(107,70,45))
            d.line((8,5,16,5),fill=(140,85,62),width=1)
            d.point((11,3),fill=(255,237,164))
            canvas.paste(im,(24*frame,36*direction),im)
    return canvas

character_sheet((235,174,122),(72,140,185),(93,63,49),(229,185,98)).save(art/"farmer.png")
for i,palette in enumerate([
    ((205,146,106),(191,96,97),(98,65,48),(232,191,93)),
    ((240,197,159),(103,151,98),(92,65,41),(218,179,89)),
    ((160,112,83),(152,112,170),(48,39,46),(224,192,107))
],1):
    character_sheet(*palette,apron=(i==2)).save(art/f"npc{i}.png")

# Ornamented 8-icon hotbar, clear identifiable tools at mobile size.
icons=Image.new("RGBA",(384,48),(0,0,0,0))
for i in range(8):
    im=Image.new("RGBA",(48,48),(0,0,0,0));d=ImageDraw.Draw(im)
    ink=(50,42,35,255)
    def ln(coords,col,width=4):d.line(coords,fill=col,width=width,joint="curve")
    if i in (0,4):
        ln([(15,37),(31,12)],ink,9);ln([(15,35),(29,14)],(155,97,54),5)
        if i==0:
            d.polygon([(28,8),(41,12),(38,23),(25,20)],fill=(171,190,192),outline=ink)
            ln([(29,11),(38,14)],(243,246,219),2)
        else:
            d.polygon([(28,7),(41,5),(42,24),(31,23)],fill=(148,178,186),outline=ink)
            ln([(31,10),(40,8)],(241,245,224),2)
    elif i==1: # bag of seeds
        d.polygon([(15,16),(34,16),(38,33),(34,41),(12,39),(10,30)],fill=(187,124,66),outline=ink)
        d.rectangle((17,9,30,15),fill=(118,83,54),outline=ink)
        for p in [(20,25),(29,30),(23,34)]:
            d.ellipse((p[0]-3,p[1]-4,p[0]+3,p[1]+4),fill=(237,202,120),outline=(119,82,45))
        ln([(14,18),(32,18)],(247,217,149),2)
    elif i==2: # bright water pail
        d.polygon([(9,19),(32,19),(33,38),(13,40)],fill=(84,160,187),outline=ink)
        d.arc((15,5,37,28),190,350,fill=(196,218,211),width=4)
        d.polygon([(30,21),(44,15),(45,19),(32,28)],fill=(123,189,211),outline=ink)
        for p in [(40,30),(43,36)]:d.ellipse((p[0],p[1],p[0]+4,p[1]+6),fill=(106,196,241))
        ln([(14,23),(29,23)],(180,234,247),2)
    elif i==3: # curved silver sickle
        ln([(17,40),(25,24)],ink,10);ln([(18,38),(25,25)],(169,110,57),6)
        d.arc((12,6,42,32),start=10,end=260,fill=ink,width=8)
        d.arc((13,7,41,31),start=10,end=255,fill=(202,223,218),width=5)
    elif i==5:
        ln([(13,42),(26,6)],(141,97,63),4)
        d.arc((22,5,42,26),220,420,fill=(209,222,214),width=2)
        d.ellipse((27,28,42,38),fill=(91,157,193),outline=ink,width=2)
        d.polygon([(27,34),(20,27),(21,41)],fill=(75,138,184))
        d.point((38,31),fill=ink)
    elif i==6: # market basket
        d.polygon([(9,21),(40,21),(36,40),(13,40)],fill=(180,115,59),outline=ink)
        d.arc((15,6,34,29),180,360,fill=(239,204,140),width=5)
        for x in [17,24,31]:ln([(x,25),(x,37)],(240,185,111),2)
        d.ellipse((19,18,28,27),fill=(119,170,76))
    else: # bed / sleep
        d.rounded_rectangle((8,24,41,38),radius=3,fill=(130,174,182),outline=ink,width=3)
        d.rounded_rectangle((8,21,22,30),radius=3,fill=(240,228,190),outline=ink,width=2)
        ln([(7,37),(7,44)],(118,78,54),4);ln([(42,37),(42,44)],(118,78,54),4)
        for x,y in [(31,9),(36,7),(36,14)]:
            d.point((x,y),fill=(255,231,138))
    icons.paste(im,(48*i,0),im)
icons.save(art/"tool_icons.png")

print("MAJOR ART: farm terrain, 4 soil conditions, 48 crop frames across 12 crops, 4 animated portraits, 8 tool icons")
for nm in ['farm_ground.png','farm_soil.png','crops.png','farmer.png','tool_icons.png']:
    print(nm,(art/nm).stat().st_size)
