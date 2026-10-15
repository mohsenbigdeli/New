extends RefCounted
# Greenfield Reborn Farming Plus v0.4 - independent farming simulation.
const SEASONS = [1, 2, 4, 8]
const ALLOWED = [1,6,6,9,9,1,6,2,6,9,4,6]
const REGROW = [0,0,2,0,0,0,3,2,0,0,0,2]
const SEED_BASE = [5,2,2,4,2,3,0,0,0,3,0,0]
const LEVEL_XP = [0,45,120,240,400,650,950,1350,1850,2500]
var w: Node2D
var stock: Array = SEED_BASE.duplicate()
var water: int = 28
var water_max: int = 28
var watering_tier: int = 0
var fertilizer: int = 3
var xp: int = 0
var level: int = 1
var shop_page: int = 0
var sprinklers: Array = []
var shipments: Dictionary = {}
var fish_delivered: int = 0
var wood_delivered: int = 0
var harvests: int = 0
var earned: int = 0
var festival_done: bool = false
var daily_goal: int = 0
var daily_progress: int = 0

func _init(world: Node2D) -> void:
    w = world

func from_dict(d: Dictionary) -> void:
    if d.is_empty():
        _sync()
        return
    var old_stock: Array = d.get("stock", SEED_BASE)
    for i in range(mini(old_stock.size(),stock.size())):
        stock[i] = maxi(0,int(old_stock[i]))
    water_max = maxi(20,int(d.get("water_max",28)))
    water = clampi(int(d.get("water",28)),0,water_max)
    watering_tier = clampi(int(d.get("tier",0)),0,2)
    fertilizer = maxi(0,int(d.get("fertilizer",3)))
    xp = maxi(0,int(d.get("xp",0)))
    level = clampi(int(d.get("level",1)),1,10)
    sprinklers.clear()
    for p in d.get("sprinklers",[]):
        if p is Array and p.size()>=2:
            sprinklers.append(Vector2i(int(p[0]),int(p[1])))
    shipments = d.get("shipments",{})
    fish_delivered = int(d.get("fish_delivered",0))
    wood_delivered = int(d.get("wood_delivered",0))
    harvests = int(d.get("harvests",0))
    earned = int(d.get("earned",0))
    festival_done = bool(d.get("festival_done",false))
    daily_goal = int(d.get("daily_goal",0))
    daily_progress = int(d.get("daily_progress",0))
    _sync()

func to_dict() -> Dictionary:
    var ar: Array = []
    for p in sprinklers:
        ar.append([p.x,p.y])
    return {"stock":stock,"water":water,"water_max":water_max,"tier":watering_tier,"fertilizer":fertilizer,"xp":xp,"level":level,"sprinklers":ar,"shipments":shipments,"fish_delivered":fish_delivered,"wood_delivered":wood_delivered,"harvests":harvests,"earned":earned,"festival_done":festival_done,"daily_goal":daily_goal,"daily_progress":daily_progress}

func _sync() -> void:
    w.seed_count=0
    for n in stock:
        w.seed_count+=int(n)

func selected_stock() -> int:
    return int(stock[w.seed_kind])

func _cost(i: int) -> int:
    return int(w.COSTS[i])

func season_ok(i: int) -> bool:
    return (int(ALLOWED[i]) & int(SEASONS[w.season])) != 0

func _cell_state(c: Vector2i) -> Dictionary:
    return w.plots.get(c,{"tilled":false,"watered":false,"crop":-1,"age":0,"fert":0,"regrow":0})

func _spend(amount: float) -> bool:
    if w.stamina < amount:
        w._tell("Too tired. Visit your cottage and rest.")
        return false
    w.stamina-=amount
    return true

func _grow_time(kind: int, fertilized: int, is_regrowing: bool = false) -> int:
    if is_regrowing and int(REGROW[kind])>0:
        return int(REGROW[kind])
    return maxi(1,int(w.DAYS[kind])-(1 if fertilized>=2 else 0))

func _award_xp(points: int) -> void:
    xp+=points
    while level < 10 and xp>=LEVEL_XP[level]:
        level+=1
        w._tell("FARMING LEVEL %d! Your tools use less energy." % level,5)
        w._float("FARM +1",w.position_farmer)

func _effect_color(kind: int) -> Color:
    var palette: Array = [Color.WHITE,Color(1,0.97,0.89),Color(0.82,1,0.89),Color(0.95,0.92,1),Color(1,0.88,0.95),Color(1,0.76,0.71),Color(1,0.91,0.67),Color(1,0.68,0.69),Color(0.96,0.96,0.67),Color(1,0.96,0.80),Color(1,0.95,0.45),Color(1,0.64,0.45)]
    return palette[kind%palette.size()]

func act(cell: Vector2i) -> void:
    if w.chosen==2 and water<=0 and w.position_farmer.distance_to(Vector2(685,585))<230.0:
        water=water_max
        w._tell("Watering can refilled at the pond: %d/%d" % [water,water_max],4)
        w._float("REFILL",w.position_farmer)
        w._save_state()
        return
    if cell.x < 0:
        cell=w._choose_plot()
    if not w._inside(cell) or w.position_farmer.distance_to(w._cell_pos(cell)) > 155.0:
        if w.chosen==2 and w.position_farmer.distance_to(Vector2(685,585))<240.0:
            water=water_max
            w._tell("Refilled watering can at the pond: %d/%d" % [water,water_max],4)
            w._float("+ WATER",w.position_farmer)
            w._save_state()
        else:
            w._tell("Stand beside your farming plots first.")
        return
    var s: Dictionary = _cell_state(cell)
    var kind: int = int(s.get("crop",-1))
    var cost_energy: float = maxf(0.65,2.0-float(level-1)*0.14)
    match w.chosen:
        0:
            if not bool(s.get("tilled",false)):
                if not _spend(cost_energy):return
                s["tilled"]=true
                s["watered"]=w.rain
                w._tell("Soil ready. Plant seeds or add fertilizer.")
                w._float("TILLED",w._cell_pos(cell))
            elif int(s.get("fert",0))==0 and fertilizer>0 and kind<0:
                fertilizer-=1
                s["fert"]=2
                w._tell("Rich fertilizer applied. Faster growth and better crops!")
                w._float("+FERT",w._cell_pos(cell))
            else:
                w._tell("Already tilled. Select SEEDS to plant.")
        1:
            if not bool(s.get("tilled",false)):
                w._tell("Till the earth with the HOE first.")
            elif kind>=0:
                w._tell("A crop is already growing in this plot.")
            elif sprinklers.has(cell):
                w._tell("The sprinkler occupies this tile.")
            elif not season_ok(w.seed_kind):
                w._tell("%s cannot grow in this season. Change seed type." % w.CROPS[w.seed_kind],5)
            elif selected_stock()<=0:
                w._tell("No %s seeds. Buy them in the market." % w.CROPS[w.seed_kind])
            else:
                stock[w.seed_kind]=selected_stock()-1
                s["crop"]=w.seed_kind
                s["age"]=0
                s["regrow"]=0
                s["watered"]=bool(s.get("watered",false)) or w.rain
                w.planted_total+=1
                _sync()
                w._tell("Planted %s! Water the soil before sleeping." % w.CROPS[w.seed_kind])
                w._float("+ SEED",w._cell_pos(cell))
        2:
            var area: Array = [cell]
            if watering_tier>=1:
                area.append(cell+Vector2i(1,0))
                area.append(cell+Vector2i(-1,0))
                area.append(cell+Vector2i(0,1))
                area.append(cell+Vector2i(0,-1))
            if watering_tier>=2:
                for xx in [-1,1]:
                    for yy in [-1,1]:
                        area.append(cell+Vector2i(xx,yy))
            var watered_count: int=0
            for p in area:
                if not w._inside(p) or not w.plots.has(p):continue
                var q: Dictionary = w.plots[p]
                if not q.get("tilled",false) or q.get("watered",false):continue
                if water<=0:break
                if not _spend(maxf(0.65,1.8-float(level-1)*0.13)):break
                q["watered"]=true
                w.plots[p]=q
                water-=1
                watered_count+=1
            if watered_count>0:
                w._tell("Watered %d plot(s). Watering can %d/%d" % [watered_count,water,water_max])
                w._float("WATER +%d" % watered_count,w._cell_pos(cell))
            elif water<=0:
                w._tell("Watering can empty! Refill at the pond near the bridge.",5)
            else:
                w._tell("This soil is already wet, or needs tilling.")
        3:
            if kind<0:
                w._tell("Nothing planted here yet.")
            elif int(s.get("age",0)) < _grow_time(kind,int(s.get("fert",0)),int(s.get("regrow",0))>0):
                var remaining: int = _grow_time(kind,int(s.get("fert",0)),int(s.get("regrow",0))>0)-int(s.get("age",0))
                w._tell("%s: %d watered night(s) until harvest." % [w.CROPS[kind],remaining])
            else:
                if not _spend(1):return
                var fert: int = int(s.get("fert",0))
                var chance: float = 0.055+float(level)*0.025+float(fert)*0.08
                var quality: int = 2 if w.rng.randf()<chance*0.23 else (1 if w.rng.randf()<chance else 0)
                var yield_count: int = 1+(1 if kind in [2,6,7,11] else 0)
                if w.rng.randf()<0.16:yield_count+=1
                var base: int=int(w.SALES[kind])*yield_count
                var gain: int=int(float(base)*([1.0,1.25,1.55][quality]))
                w.coins+=gain
                earned+=gain
                w.crop_basket+=yield_count
                harvests+=yield_count
                daily_progress+=yield_count
                var key: String=w.CROPS[kind]
                shipments[key]=int(shipments.get(key,0))+yield_count
                _award_xp(11+yield_count*4)
                w._float("+%dg" % gain,w._cell_pos(cell))
                var symbol: String = [""," ★"," ★★"][quality]
                w._tell("Harvested %d %s%s! +%d gold" % [yield_count,w.CROPS[kind],symbol,gain],5)
                if REGROW[kind]>0:
                    s["age"]=0
                    s["regrow"]=1
                    s["watered"]=false
                    w._tell("%s harvested! The plant will regrow in %d days." % [w.CROPS[kind],REGROW[kind]],5)
                else:
                    s["crop"]=-1
                    s["age"]=0
                    s["watered"]=false
                if w.crop_basket>=5 and not w.quest_done:
                    w.quest_done=true
                    w.coins+=150
                    w._float("QUEST +150g",w.position_farmer)
                _check_orders()
    w.plots[cell]=s
    w._save_state()
    w.queue_redraw()

func _check_orders() -> void:
    if daily_progress >= daily_goal and daily_goal>0:
        var reward: int=100+daily_goal*8
        w.coins+=reward
        earned+=reward
        daily_goal=0
        w._tell("Harvest contract complete! Bonus +%dg" % reward,5)
        w._float("ORDER +%dg" % reward,w.position_farmer)
    if harvests>=25 and not festival_done:
        festival_done=true
        w.coins+=550
        w._tell("Harvest Festival milestone! +550 gold",5)

func next_day(rained_yesterday: bool, rains_today: bool) -> void:
    var changes:int=0
    for c in w.plots.keys():
        var p: Dictionary=w.plots[c]
        var kind: int=int(p.get("crop",-1))
        if kind>=0:
            if (int(ALLOWED[kind]) & int(SEASONS[w.season])) == 0:
                p["crop"]=-1
                p["age"]=0
                p["regrow"]=0
            elif bool(p.get("watered",false)) or rained_yesterday:
                p["age"]=mini(20,int(p.get("age",0))+1)
                changes+=1
        p["watered"]=rains_today
        w.plots[c]=p
    for p in sprinklers:
        for xo in range(-1,2):
            for yo in range(-1,2):
                var c: Vector2i=p+Vector2i(xo,yo)
                if w.plots.has(c):
                    var info: Dictionary=w.plots[c]
                    if info.get("tilled",false):
                        info["watered"]=true
                        w.plots[c]=info
    daily_progress=0
    daily_goal=3+(w.day%4)
    if rains_today:
        w._tell("Rain has watered your fields! %d crops grew overnight." % changes,5)
    else:
        w._tell("Good morning! %d crops grew. Harvest order: %d crops." % [changes,daily_goal],5)

func buy(kind: int) -> void:
    if kind<0 or kind>=w.CROPS.size():return
    if w.coins<_cost(kind):
        w._tell("Not enough gold to buy those seeds.")
        return
    w.coins-=_cost(kind)
    stock[kind]=int(stock[kind])+1
    w.seed_kind=kind
    _sync()
    w._tell("Bought 1 %s seed. In bag: %d" % [w.CROPS[kind],stock[kind]])
    w._save_state()

func buy_upgrade(kind: int) -> void:
    var cost: int=[75,220,320,180,150][kind]
    if w.coins<cost:
        w._tell("Need %d gold. Harvest and sell more crops." % cost)
        return
    match kind:
        0:
            fertilizer+=5
            w._tell("Bought 5 fertilizer. Apply with HOE to tilled empty soil.")
        1:
            if watering_tier>=2:
                w._tell("Your watering can is already fully upgraded!")
                return
            watering_tier+=1
            water_max+=16
            water=water_max
            w._tell("Watering can upgraded! Covers %d plots per use." % (5 if watering_tier==1 else 9),5)
        2:
            if w.wood < 8:
                w._tell("Gather 8 wood to craft a sprinkler.")
                return
            var spots: Array=[Vector2i(5,3),Vector2i(2,3),Vector2i(8,3),Vector2i(5,1),Vector2i(5,5)]
            var chosen_spot=Vector2i(-1,-1)
            for c in spots:
                var state: Dictionary=_cell_state(c)
                if not sprinklers.has(c) and int(state.get("crop",-1))<0:
                    chosen_spot=c
                    break
            if chosen_spot.x<0:
                w._tell("No free sprinkler space in the center of the field.")
                return
            sprinklers.append(chosen_spot)
            w.wood-=8
            var state: Dictionary=_cell_state(chosen_spot)
            state["tilled"]=true
            state["watered"]=true
            w.plots[chosen_spot]=state
            w._tell("Sprinkler installed! It waters adjacent 3x3 plots at sunrise.",5)
        3:
            water_max+=20
            water=water_max
            w._tell("Added +20 capacity to your watering can.")
        4:
            w.stamina=100
            w._tell("Farmers' lunch: energy completely restored!")
    w.coins-=cost
    w._save_state()

func shop_tap(p: Vector2, size: Vector2) -> void:
    var x: float=p.x/size.x*960.0
    var y: float=p.y/size.y*540.0
    if y<158 or x>710.0:
        w.menu=""
        return
    if y>424:
        shop_page=(shop_page+1)%4
        return
    var row: int=int((y-171.0)/43.0)
    if row<0 or row>=5:return
    if shop_page<3:
        var kind:int=shop_page*5+row
        if kind<w.CROPS.size():buy(kind)
    else: buy_upgrade(row)

func draw_shop(h: Control) -> void:
    h.draw_rect(Rect2(0,0,960,540),Color(0.04,0.05,0.04,0.76))
    h.panel(Rect2(227,79,508,385),Color(0.16,0.15,0.12,0.98),Color(0.88,0.60,0.34))
    h.label("VALLEY MARKET  ·  PAGE %d/4" % [shop_page+1],253,120,23,Color(1,0.84,0.51))
    h.label("X   CLOSE",646,122,13)
    for row in range(5):
        var y: float=169+float(row)*43.0
        h.panel(Rect2(252,y-6,457,36),Color(0.27,0.22,0.17,0.96))
        if shop_page<3:
            var k:int=shop_page*5+row
            if k<w.CROPS.size():
                h.label("%s  %s" % [w.CROPS[k],"IN SEASON" if season_ok(k) else "OUT OF SEASON"],263,y+17,15)
                h.label("%dg   OWN:%d" % [_cost(k),int(stock[k])],560,y+17,14,Color(1,0.84,0.51))
        else:
            var labels: Array=["Fertilizer +5","Upgrade watering radius","Craft 3x3 sprinkler (8 wood)","Water tank +20","Farm lunch / recover energy"]
            var costs: Array=[75,220,320,180,150]
            h.label(labels[row],263,y+17,15)
            h.label("%dg" % costs[row],647,y+17,14,Color(1,0.84,0.51))
    h.panel(Rect2(251,421,457,34),Color(0.56,0.33,0.18),Color(0.88,0.71,0.44))
    h.label("NEXT PAGE   →  seeds / tools / supplies",273,444,16,Color(1,0.96,0.75))

func draw_world() -> void:
    for c in w.plots.keys():
        var p: Dictionary=w.plots[c]
        var pos: Vector2=w._cell_pos(c)
        if p.get("watered",false):
            w.draw_rect(Rect2(pos-Vector2(14,8),Vector2(28,16)),Color(0.10,0.38,0.67,0.27))
            w.draw_line(pos+Vector2(-8,3),pos+Vector2(5,2),Color(0.61,0.86,1.0,0.37),1.1)
        if int(p.get("fert",0))>0:
            w.draw_circle(pos+Vector2(-13,7),2.0,Color(0.93,0.83,0.40,0.92))
        var kind: int=int(p.get("crop",-1))
        if kind>=0:
            var age: int=int(p.get("age",0))
            var days: int=_grow_time(kind,int(p.get("fert",0)),int(p.get("regrow",0))>0)
            if age>=days:
                var wave: float=0.6+0.4*sin(w.birds_time*3.0+float(c.x))
                w.draw_arc(pos+Vector2(0,-21),24,0,TAU,22,Color(1,0.91,0.49,0.43+0.33*wave),2.0)
                w.draw_string(ThemeDB.fallback_font,pos+Vector2(-22,-45),"READY",HORIZONTAL_ALIGNMENT_CENTER,46,11,Color(1,1,0.64,0.92))
            elif age<=1:
                w.draw_circle(pos+Vector2(0,-5),2.2,Color(0.65,0.86,0.28,0.95))
    for c in sprinklers:
        var pos: Vector2=w._cell_pos(c)
        w.draw_rect(Rect2(pos-Vector2(10,18),Vector2(20,20)),Color(0.34,0.54,0.66))
        w.draw_rect(Rect2(pos-Vector2(4,29),Vector2(8,13)),Color(0.73,0.83,0.88))
        w.draw_circle(pos-Vector2(0,29),6.0,Color(0.38,0.66,0.88))
        if w.rain:
            w.draw_arc(pos-Vector2(0,28),17,0,TAU,20,Color(0.65,0.86,1,0.56),1.1)
