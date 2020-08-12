pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--bit.bash
--by fred bednarski
--@level27geek


--this code is probably a mess
--i wouldn't know, bc it is
--realy the first thing
--that i have ever coded.
--find out more at:
--level0gamedev.blogspot.com

--edit: i have learned a lot in
--making of this game. i now 
--know for sure, the code is a 
--mess. a lot of different 
--naming conventions and 
--spaghetti code in general.
--here be dragons.

music(0)

function _init()

function gpal()
 pal()
 palt (0, false)
 palt (15, true)
end

gpal()
gamestate=0

frame_num=1
once = 0

--paddle
padx=52
pady=120
padyconstant=pady
padw=23
padh=4
padspeed=0
padspeedmax=10
padcenterx=padx+padw/2
padcol=12

--ball
ballsize=5
ballx=(padx+padx+padw)/2-2 --centers the ball on the paddle for serve
bally=pady-ballsize-1
ballsprite=2
ballxdir=0
ballydir=0
ballspeed=0
startspeed=1.9
servedir=startspeed
servei=0
ballcenterx=ballx+ballsize/2
ballcentery=bally+ballsize/2

--playfield
minx=7
maxx=120
miny=15
maxy=127

--endframe
frame_col =12
frame = {}
frame_action = 0

--intro_bg
grid_t=0

bugs ={} --table for enemies
explosions ={} --table for particles
trails ={} --table for trail particle

level=1
leveldone=true
currentlevel = 0
score=0
scoremulti=10 --score multiplier, large to avoid rounding errors
lives=4 
newball=1
hitx=0
camoffset = 0 --used for screenshake

--timer
timerx1 = 41
timery1 = 9
timerx2 = 86
timery2 = 11
timercol = 12 
timerxmax=timerx2
timerlen=timerx2-timerx1
timerlenmax=timerxmax-timerx1

--text info up top
topinf = "sector "..level
topcol1 = 12
topcol2 = 12

symbols={"„","“","˜","ˆ","","€","’","…","†","Š","Œ","","‚"}
symbol=flr(rnd(#symbols))+1

--powerups todo
bonuses = {powerups ={} }

powerups = {
 {name = "pad size+",label="p", col=12, func= function() padw+=4 padh+=2 end},
 {name = "pad size-",label="p", col=8, func= function() padw-=4 padh-=2 end},
 {name = "slow ball",label="s", col=12, func= function() if ballspeed>=2+max(0.5,level/7) then ball_speed_mod(min(-level/7,-0.5)) end end},     
 {name = "fast ball",label="s", col=8, func= function() ball_speed_mod(0.5) end},
 {name = "ball size+",label="b", col=12, func= function() ballsize+=2 ballsprite+=1 end},     
 {name = "ball size-",label="b", col=8, func= function() ballsize-=2 ballsprite-=1 end},
 {name = "error!",label="nil", col=8, func= function() bosses[bosses.select].func() end}
}

 
--glitches
glitch_noise_factor = 0
glitch_line_factor = 0 
--timers for different glitches
tot1 = nil -- total glitch out
tot2 = nil -- wobble
tot3 = nil -- glitch_triline
tot4 = nil -- glitch_fuzz

--bosses
bosses={
 {name="dr0p.dat", inf="bulky trojan able to push data down into secure memory and brick the cpu.  ", func = function() bug_down() end},
 {name="bre3d-v8", inf="lower memory virus that clones itself and corrupts data in a rapid manner.  ", func = function() create_breed() end},
 {name="cysta_b", inf="an ever expanding rootkit. disables sys functions and makes it unstable.   ", func = function() create_copy_bug() end},
 {name="happy.84",inf="a polymorphic worm with surveillance protocols and very unstable behavior.  ", func = function() bugmix() end},
 select=1
}
bi={} --boss indicator
bi.x=85
bi.y=55 

flashes={}
keys={} --for extended key handler
init_keys()
tbx_init()


end



function movepaddle()
 padcol=12
 pady=padyconstant
  if is_held(0) and padx>1 then
   padspeed-=3
  elseif is_held(1) and padx<(127-padw) then
   padspeed+=3
  end 
  padx+=padspeed
  if newball==1 then
   ballx=padx+padw/2-ballsize/2
  end
  --contain the paddle movement
  --to within the playfield
  if padx<minx then
			padx=minx
			padspeed=0
  elseif padx+padw>maxx then
   padx=maxx-padw
   padspeed=0
  end
  if padspeed>padspeedmax then
   padspeed=padspeedmax
  end
end


function padspeed_down()
 padspeed = 0.5 * padspeed
 if padspeed>-1 and padspeed<1 then
  padspeed=0
 end 
end 


function serve()
 if newball==1 and
 is_pressed(4)  and
 lives!=-1 and 
 generating != true  then 
  newball=0
  ballydir-=startspeed
  ballxdir+=servedir
  music(4)
  end
end

function serve_help()
  if (is_pressed(1)) servedir=1
  if (is_pressed(0)) servedir=-1
  servei+=servedir
  if (servei<=padx) servei = padx+padw-1
  if (servei>=padx+padw) servei=padx+1
end

function serve_line()
 if newball==1 then
  for i=1,3 do
   pset(servei,pady+i,12)
  end 
 end
end

function moveball()
  ballhit = false
  ballx+=ballxdir
  bally+=ballydir
  ballcenterx=ballx+ballsize/2
  ballcentery=bally+ballsize/2
  if ballxdir!=0 then trail_create(ballx,bally,12,ballspeed+4,ballsize-1) end
end


function wallbounce()
 --left
  if ballx<minx then
   ballxdir=-ballxdir
   ballx+=1
   sfx(4)
   create_explosion(ballx,bally,12,2,2,4)
  end
 --right
  if ballx>=maxx-ballsize then
   ballxdir=-ballxdir
   ballx-=1
   sfx(4)
   create_explosion(ballx+ballsize,bally,12,2,2,4)
  end
 --top
  if bally<miny then
   ballydir=-ballydir
   bally+=1
   sfx(4)
   create_explosion(ballx+3,bally,12,2,2,4)
  end
end


function hitball()
 --check if ball is within paddle
  if ballx>padx-2 and
  ballx<=padx+padw+1 and
  bally>=pady-ballsize and
  bally<pady+padh and
 --and is travelling down
  ballydir>0 then
  --pitagoran therum keeps
  --overall speed constant
   ballspeed=sqrt(ballxdir*ballxdir+ballydir*ballydir)
  
  --slice mechanic?
  --only small changes to ballxdir
   if is_held(0) or is_held(1) then
    ballxdir+=padspeed/4.2
   else 
   --change ball angle
   --based on where the ball
   --hit the paddle
    padcenterx=padx+padw/2
    hitx=(ballcenterx-padcenterx)/(padw/2)
    ballxdir=ballspeed*hitx
   end
   if ballxdir==0 then
    ballxdir=rnd(1)-2/10  
   end
  --elimnate ball going crazy
  --when x dir > speed
   if ballxdir>ballspeed then
    ballxdir=ballspeed*0.9
   elseif ballxdir<-ballspeed then
    ballxdir=ballspeed*0.9*(-1)
   end  
  --speed up the ball
   ballspeed+=(min(level,8)/100)
  --compute ball y direction
  --to keep speed constant
   ballydir=sqrt(ballspeed*ballspeed-ballxdir*ballxdir)*(-1)
   sfx(3)
   scoremulti=10
   padcol=7
   pady+=2
   create_explosion(ballcenterx,ballcentery+3,12,6,1,6) 
  end
end


function lose()
  if bally>maxy then
   music(-1)
   if (lives>0) sfx(17)
   if lives!=-1 then
 	  camoffset=2
 	  create_pixelfall(ballx+ballsize/2,bally+ballsize/2,12,2,-1)
 	  create_pixelfall(ballx+ballsize/2,bally+ballsize/2,7,2,-1)
 	  newball=1
 	  lives-=1
 	  scoremulti=10
 	  ballx=(padx+padx+padw)/2-3
    bally=pady-ballsize-1
    ballxdir=0
    ballydir=0
    basic_sizes()
    tot3=10
    for i in all(bonuses) do
     flash_square_crreate(i,6)
     create_explosion(i.x+4,i.y+8,i.col,8,2,5)
     create_pixelfall(i.x+4,i.y+8,i.col,4,1)
     del(bonuses,i)
    end 
 	 else
 	  ballydir=0
 	  ballxdir=0
 	  bally=40
 	  ballx=40	  
   end
   
  end
end

 
function lose_check()
 if lives!=-1 then
  --draw the ball
   spr (ballsprite,ballx,bally)
 else
  gamestate = 1.5
  music(0, 2000)
  sfx(10)
 end
 for i in all(bugs) do
  if i.y > 110 then
   gamestate = 1.5
   music(0)
   sfx(10)
  end
 end  
end


function create_bug(sprite)
--generate random x & y
  rndx=flr(rnd(7))*16+8
  rndy=flr(rnd(8))*8+15
--responsible for assigning
--random values to enemies
 local sprites={16,32}
 local sn = flr(rnd(2)+1) 
 local o={}
 o.sprite= sprite or sprites[sn]
 if o.sprite == 16 then
  o.col = 8
  o.point = 10
 elseif o.sprite == 32 then
  o.col = 9
  o.point = 10
 elseif o.sprite==4 then
  --breed virus
  o.col = 8
  o.w = 1 
  o.y = flr(rnd(10))*8+32
  o.x = flr(rnd(7))*16+8
  if o.x <=64 then
   o.xd=0.25
  else
   o.xd=-0.25
  end  
  o.point = 0
  create_explosion(o.x+4,o.y+4,o.col,8,2,10)
  create_pixelfall(o.x+4,o.y+8,5,8,1)
     
 else 
  o.col = 13 
  o.point = 0
 end  
 o.x=o.x or rndx
 o.y=o.y or rndy
 o.w=o.w or 2
 o.h=1

 local tries = 0
 local overlapped = true
  while overlapped and tries<250 do
   overlapped = false
   foreach(bugs, function(bugs)
    if bugs.x<o.x+o.w*8 and bugs.x+bugs.w*8>o.x and bugs.y<o.y+o.h*8 and bugs.y+bugs.h*8>o.y
    then
     tries+=1
     overlapped = true
     o.x=flr(rnd(7))*16+8
     o.y=flr(rnd(8))*8+15
    end
   end)
  end
  if tries<250 then
   add(bugs, o)
  end 
end


function draw_bug (o)
--draw an enemy with values
--established in create_bug
  spr(o.sprite,o.x,o.y,o.w,o.h)
  --glitchy effect for bricks
  if o.w==2 then
   for y=o.y+2,o.y+6 do
    for x=o.x+2,o.x+14 do
      if pget(x,y)==0 
      and rnd(1)>0.8 then 
       pset(x,y,o.col) 
      end
    end
   end
  end 
end


function col_bugball()
  for bug in all(bugs) do
    if bug.x+1 < ballcenterx+ballsize/2 and
       bug.x-1 + bug.w * 8 > ballcenterx-ballsize/2 and
       bug.y+1 < ballcentery+ballsize/2 and
       bug.y-1 + bug.h * 8 > ballcentery-ballsize/2 
       --trying to fix some fringe 
       --collision issues with those
       and not ballhit then
        flr(ballx)
        flr(bally)
        ballx -=ballxdir
        bally -=ballydir
        
        
      --bounce horizontal
      if
       (ballx+ballsize-1 < bug.x or
       ballx+1 > bug.x + bug.w * 8)
      then
        ballxdir = -ballxdir  
      -- since you've ruled out a horizontal bounce, we know
      -- for a fact that it'll be a vertical bounce.
      --bounce vertical
      else
        ballydir = -ballydir
      end
      -- since there's definitely a bounce, the sound can be stated once
      sfx(5)
      ball_speed_mod(0.005+min(level,4)/1500)
      ballhit = false
      create_explosion(bug.x+bug.w*4,bug.y+bug.h*4,bug.col,8,2,10)
      create_pixelfall(bug.x+bug.w*4,bug.y+bug.h*8,bug.col,8,1)
      if bug.sprite == 16 or bug.sprite == 32 then
       create_bonus(bug.x+bug.w*4,bug.y+bug.h*8)
      end
      flash_square_crreate(bug,6)
      hitbug(bug)
      camoffset-=0.5 + 0.25 * #explosions
      break
    end
  end
end


function hitbug(bug)
 if bug.sprite == 32 then
  bug.sprite = 16
  bug.col = 8
 else 
 del(bugs, bug)
 end
 timerx2+=0.5+level/2+scoremulti/5
 if bug.point==10 then score += scoremulti end
 scoremulti+=level
end


function start_level()
 frame_action=0
 if (level==1) glitch_line_factor=0
 generating = true
 if currentlevel < level 
 and #bugs < 20+level then
  create_bug()
 else currentlevel=level
 generating = false 
 end  
 if generating==false and leveldone==true then
  bosses[bosses.select].func()
  leveldone=false 
 end
end


--random number from to int
function randint(minn, maxn)
  local range=(maxn+1)-minn
  return flr(rnd(range)+minn)
end


function grid_draw()
 local t=1
 local x1=7
 local y1=15
 while t<=8 do
  line (x1,15,x1,127,1)
  line (7,y1,119,y1,1)
  t+=1
  x1+=16
  y1+=16
 end
end 


function screenshake()
 --moves camoffset back to zero
 --1px at a time, flipping sign
 --every time
 if camoffset > 2 then camoffset = 2
  elseif camoffset < -2 then camoffset = -2
 end
 if (camoffset==0) return
 if (camoffset<0) then
  camoffset+=0.25
 end
 if (camoffset>0) then
  camoffset-=0.25
 end
 camoffset*=-1
end


function create_pixelfall (x,y,col,spread,direction)
 local pixelfall = {}
 pixelfall.x = x
 pixelfall.y = y
 pixelfall.bits = {}
 for i=0,randint(10,20) do
  local bit = {}
  bit.x = x + randint(-spread,spread)
  bit.y = y
  local pcol = {2,8}
  bit.col = col
  bit.xdir = 0
  bit.ydir = direction*rnd(4)+0.2
  add (pixelfall.bits, bit)
  end
 pixelfall.step = 0
 pixelfall.maxsize = randint(12,20)
 add (explosions, pixelfall) 
end 


function create_explosion (x,y,col,count,spread,ticks)
 local explosion = {}
 explosion.x = x
 explosion.y = y
 explosion.bits = {}
 for i=0,randint(count,count*2)+#explosions*2 do
  local bit = {}
  bit.x = x
  bit.y = y
  bit.col = col
  bit.xdir = randint(-spread,spread)
  bit.ydir = randint(-spread,spread)
   if bit.xdir==0 and bit.ydir==0 then
    bit.ydir=spread
   end 
  add(explosion.bits, bit)
 end
 explosion.step = 0
 explosion.maxsize = ticks
 add(explosions, explosion)
end  


function explosion_update()
 for explosion in all(explosions) do
  if explosion.step <= explosion.maxsize then
   explosion.step += 1
   for bit in all(explosion.bits) do
    bit.x += bit.xdir
    bit.y += bit.ydir
   end
  else
    del(explosions, explosion)
  end
 end  
end


function explosion_draw()
 for explosion in all(explosions) do
    for bit in all(explosion.bits) do
      pset(bit.x,bit.y,bit.col)
    end
 end
end

function create_bonus(_x, _y,sp)
 local _bonus = {x = _x-4, y = _y-4}
  local var
   
   if sp!=nil then
    var = sp
   elseif #bonuses<3 and rnd(1) <0.1+scoremulti/100 then
    var = flr(rnd(#powerups)) + 1
   else
    return
   end
    _bonus.spr = powerups[var].spr
    _bonus.func = powerups[var].func
    _bonus.vel = 0.5 + rnd(0.5) 
    _bonus.col = powerups[var].col
    _bonus.w=1
    _bonus.h=1
    _bonus.label = powerups[var].label
    _bonus.name = powerups[var].name
    add(bonuses, _bonus)
end


function bonus_update()
 for i in all(bonuses) do
  --clear bonuses when there are no bricks left
  if #bugs<1 then 
   create_explosion(i.x+4,i.y+8,i.col,8,2,5)
   flash_square_crreate(i,6)
   del(bonuses,i) 
  end
  --move the bonus down
  i.y += i.vel+level/10
  trail_create(i.x+randint(-2,4),i.y-4,i.col,8,4)
  --bonus/paddle collision
  if i.x+8 >= padx and i.x <= padx+padw 
  and i.y+6 >= pady then
   create_pixelfall(i.x+4,i.y+8,i.col,4,-1)
   create_pixelfall(i.x+4,i.y+8,i.col,4,-1)
   create_explosion(i.x+4,i.y+8,i.col,8,2,5)
   frame_num=1
   i.func()
   padcol=7
   pady+=1
   flash_square_crreate(i,6)
   topinf=i.name
   topcol1=i.col
   topcol2=7
   del(bonuses,i)
   score+=64
   if i.col == 12 then
   sfx(6)
   end
   if i.col == 8 then
   sfx(7)
   end
  end
  --destroy brick when it 
  --reaches the bottom 
  if i.y+8 >= 128 then
   create_explosion(i.x+4,i.y+8,i.col,8,2,5)
   flash_square_crreate(i,6)
   del(bonuses,i)
  end 
 end 
end

function bonus_draw()
 for i in all(bonuses) do
 -- spr(i.spr,i.x,i.y)
 rect(i.x,i.y,i.x+7,i.y+7,flash2colors(i.col,7,3))
 print(i.label,i.x+2,i.y+2,flash2colors(i.col,7,3))
 end
end

function end_level()
 if #bugs==0 then
 if not level_transit then tot3=10 end 
  if once == 0 then
  sfx(9)
  music(0)
  
  once = 1
  end
  frame_action = 1
  level_transit=true
  timerx2+=1
  ballxdir=0
  ballydir=0
  ballx=(padx+padx+padw)/2-2 --centers the ball on the paddle for serve
  bally=pady-ballsize-1
  newball=1
  scoremulti=10 	
  create_pixelfall(ballx+ballsize/2,pady-2,7,ballsize/2-1,-1)
 	create_pixelfall(padx+padw/2,pady,12,padw/2,-1)  
 	if is_pressed(4) then
   leveldone=true
   tot3=10
   frame_action = 0
   level_transit=false
   level+=1
   startspeed=startspeed+0.01*level
   timerx2 = timerxmax
   topinf= "sector "..level
   local mover = padw-23
   padx+=mover/2 -- makes paddle stay in the same place between levels
   basic_sizes() -- restarts pad and ball size between levels
   once = 0
   music(-1)
   sfx(17)
  end
  return true 
 end   
end


function init_frame()
 frame.x = -2
 frame.x2 = -1
 frame.x3 = 129
 frame.x4 = 128
 frame.r1 = 62
 frame.r2 = 62
 frame.r3 = 66
 frame.r4 = 66
end


function frame_update() 
 frame.x2 += 4
 frame.x2 = min(frame.x2,64)
 frame.x4 -= 4
 frame.x4 = max(frame.x4,64)

 if frame.x2 == 64 then
  frame.r1 -= 4
  frame.r1 = max(frame.r1,13)
  frame.r2 -= 4
  frame.r2 = max(frame.r2,32)
  frame.r3 += 4
  frame.r3 = min(frame.r3,114)
  frame.r4 += 4
  frame.r4 = min(frame.r4,98)
 end 
end

--this is a frame that comes
--up at the end of the lvl/game
function frame_control() 
 if frame_action >= 1 then
  frame_update()
 else init_frame()
 end  
end


function frame_draw()
 local mod=0
--two lines that meet in middle
 line (frame.x,63+mod,frame.x2,63+mod,frame_col)
 line (frame.x3,63+mod,frame.x4,63+mod,frame_col)
 line (frame.x,65+mod,frame.x2,65+mod,frame_col)
 line (frame.x3,65+mod,frame.x4,65+mod,frame_col)
--when they do, square appears 
 if frame.x2==64 then
  rect (frame.r1,frame.r2+mod,frame.r3,frame.r4+mod,frame_col)
  rect (frame.r1+1,frame.r2+1+mod,frame.r3-1,frame.r4-1+mod,0)
  rect (frame.r1+2,frame.r2+2+mod,frame.r3-2,frame.r4-2+mod,frame_col)
  rectfill (frame.r1+3,frame.r2+3+mod,frame.r3-3,frame.r4-3+mod,0)
  line (0,64,13,64,0)
  line (127,64,114,64,0)
 end
end

function glitch_fuzz()
  local cs=cos((frame_num%60)/60)
  cs*=0.75
  for i=0,100 do
   local b=0x6000+i*80
   local c=i/100
   local le=70
   memcpy(b,b+i%(1+cs),le)
  end
end


function glitch_noise()
 if glitch_noise_factor > 0 then
  local f = glitch_noise_factor/5
  for tx=0,16 * f  do
   for ty=0,16 * f do
   tk=rnd(3)-1 
   ta=tx*(8/f)+tk 
   tb=ty*(8/f)+tk
   tc=pget(ta,tb) 
   tc+=flr(rnd(9)/8) 
   pset(ta+rnd(3)-1,tb+rnd(3)-1,tc)
   end
  end
 end
 glitch_noise_factor-=1
 glitch_noise_factor=max(0,glitch_noise_factor)  
end


function glitch_line_random(mod)
  local source = flr(rnd(8191))
	 local range = flr(rnd(64))+64
	 local dest = 0x6000 + rnd(8191-range)-2
	 
  if mod != nil then
   local i = rnd(1)
   if i<0.5 then
    source=flr(rnd(1900)) 
   else
    source=flr(rnd(1900))+6140
   end
  end
  source+=0x6000
	 memcpy(dest,source,range)
end

function glitch_listener_draw()
 
 if tot4!=nil and tot4 > 0 then
  glitch_fuzz()
  sfx(2)
  tot4-=1
 else
  tot4=nil 
 end
 
 if tot3!=nil and tot3>0 then
  glitch_triline(20) 
  sfx(2)
  tot3-=1
 else
  tot3=nil 
 end
  
 if tot2!=nil and tot2>0  then
  filter()
  sfx(2)
  tot2-=1
 else
  tot2=nil 
 end
 
 if tot1!=nil and tot1>0  then
  glitch_total()
  sfx(2)
  tot1-=1
 else tot1=nil 
 end
end 


function glitch_triline(lines)
	local lines=lines or 64
	
	for i=1,lines do
		row=flr(rnd(128))
		row2=flr(rnd(127))
		if (row2>=row) row2+=1
		
		-- copy a row from the
		-- screen into temp memory
		memcpy(0x4300, 0x6000+64*row, 64)
		
		-- another row from the
		-- screen to our original row
		memcpy(0x6000+64*row, 0x6000+64*row2, 64)
		       
		--copy the temp row into row2's
		--original slot
		memcpy(0x6000+64*row2, 0x4300,64)
	end
end


function ball_speed_mod(mod)
 ballspeed=sqrt(ballxdir*ballxdir+ballydir*ballydir)
 ballspeed+=mod
 if ballxdir>ballspeed then
    ballxdir=ballspeed*0.9
 elseif ballxdir<-ballspeed then
    ballxdir=ballspeed*0.9*(-1)
 end    
 if ballydir>0 then
 ballydir=sqrt(ballspeed*ballspeed-ballxdir*ballxdir)
 else
 ballydir=sqrt(ballspeed*ballspeed-ballxdir*ballxdir)*-1
 end
end

function rand_glitch()
 local i = rnd(13)
 if i<1.5 then tot1=15+level
 elseif i<4 then tot2=20+10*level
 elseif i<8 then tot4=20+10*level
 else tot3=5+5*level
 end
end

function bonus_glitch()
  var = flr(rnd(#bugs))+1
  bug=bugs[var] 
  create_bonus(bug.x+bug.w*4,bug.y+bug.h*8,#powerups)
end

function bugmix()
 local a = #bugs
 for bug in all (bugs) do
  del(bugs,bug)
 end 
 for j = 1,a+1 do
  create_bug()
 end
 
 tot1=10
end

function create_copy_bug()
 --makes a brick worth 0 points
 --used in breeder
 for c = 1,flr(level/2)+1 do
  local i = #bugs
  create_bug(48)
  if i < #bugs then
   local bug = bugs[#bugs]
   create_explosion(bug.y,bug.y,bug.col,20,20,2)  
   create_pixelfall(bug.x+bug.w*4,bug.y+bug.h*8,bug.col,8,-1) 
  end
 end
 tot2 = 10 --wobble glitch effect 
 camoffset+=1
end

function bug_down()
 --drops all the bricks
 --used in drop.dat 
 if #bugs>0 then
  for bug in all(bugs) do
   bug.y+=8
   create_pixelfall(bug.x+bug.w*4,bug.y+bug.h*8,bug.col,8,-1)  
  end 
  camoffset+=1
  tot3=3
 end 
end

function create_breed()
 for i=1,flr(level/4)+1 do
  create_bug(4)
  tot3=5
  camoffset+=1
 end 
end

function breed_update(o)
--find breed viruses among bugs
 if o.w==1 then
  --animate 
  if frame_num%4==0 then
   o.sprite+=1
   if (o.sprite>7) o.sprite=4
   if (o.sprite==4) create_explosion (o.x,o.y+8,o.col,4,0.5,3)
   if (o.sprite==6) create_explosion (o.x+8,o.y+8,o.col,4,0.5,3)
  end
  --walk
  o.x+=o.xd
  if (o.x<=minx or o.x+8>maxx) o.xd*=-1
   
 
 end
end

function rand_boss_skill()
local i = rnd(9)
 if i<3 then bug_down()
 elseif i<6 then create_copy_bug()
 else create_breed()
 end
end


function timer_update()
 
 local left = timerx2-timerx1
 local right = timerxmax-timerx1
 if left<right*0.1 then
  timercol=flashrw
 elseif left<right*0.25 then
  timercol=flashbw 
 else timercol=12
 end
 
 if ballydir!=0 then
  timerx2-=level/30
 end
 if timerx2 < timerx1 then
 bosses[bosses.select].func() --this reads function from bosses table
  create_explosion(timerx1,timery1,12,10,10,4)
  timerx2=timerxmax
  timercol=8
 end
 if timerx2 >= timerxmax then
  timerx2 = timerxmax-1
 end
end

function flash2colors(one,two,delay)
 if frame_num%delay<delay/2 then
  return one
 else
  return two
 end 
end

function timer_draw()
 rectfill(timerx1,timery1,timerx2,timery2,timercol)
 print (topinf,64-#topinf*2,timery1-6,flash2colors(topcol1,topcol2,6))
end

function constrains()
 ballspeed=min(ballspeed,3.5+(level/10))
 ballsize=mid(3,ballsize,7)
 ballsprite=mid(1,ballsprite,3)
 if frame_num%3 then 
  padw=mid(15,padw,31)
  padh=4 
 end
 if frame_num==45 then
  topinf= "sector "..level
  topcol1=12
  topcol2=12
 end
end

function flash_square_crreate(thing,t)
  local square = {}
  square.col=thing.col
  square.x=thing.x
  square.y=thing.y
  square.x2=thing.x+thing.w*8
  square.y2=thing.y+thing.h*8
  square.t=t
  add (flashes,square)
end

function flash_square_update()
 for i in all(flashes) do
  local speed=0.5
  i.x+=speed
  i.y+=speed
  i.x2-=speed
  i.y2-=speed
  i.t-=speed
  if i.y>i.y2 then i.y=i.y2 end
  if i.t<=0 then
   del(flashes,i)
  end 
 end
end

function flash_square_draw()
 for i in all (flashes) do
  rect(i.x,i.y,i.x2,i.y2,i.col)
 end
end


function trail_create(_x,_y,col,delay,spread)
 --for i =0,amount do
  local bit = {}
  bit.x = _x+flr(rnd(spread))+1
  bit.y = _y+flr(rnd(spread))+1
  bit.col = col
  bit.maxsize = delay
  bit.step = 0
  add(trails, bit)
end

function trail_update()
 for bit in all(trails) do
  if bit.step<=bit.maxsize then
   if bit.step>=bit.maxsize*0.7 then
    bit.col=1
   end 
   bit.step+=1
  else
   del(trails,bit) 
  end
 end
end

function trail_draw()
 for bit in all(trails) do
  pset(bit.x,bit.y,bit.col)
 end
end

function basic_sizes()
 ballsprite=2
 ballsize=5
 padw=23
 padh=4
 bally=pady-ballsize-1
end


function glitch_total()
 for y=0,126 do
  local amp=64-y
  amp=amp*sin(tot1/5)
  amp=64-amp
  local addr=0x6000+64*y
  local addr2=0x6000+64*amp
  memcpy(addr,addr2,64)
 end
end

function filter()
 for y=0,126 do
  local tamp=sin((frame_num%127)/126)*8
  local yy=(y+frame_num*tamp)%126
  local addr=0x6000+64*y
  local addr2=flr(2*sin(yy/125))
  memcpy(addr+addr2,addr,64-addr2)
  if rnd(1.0)>0.99 then
   local x=0
   while x<128 do
    pset(x,y,1)
    x+=flr(rnd(16))
   end
  end
 end
end


function xy_to_mem(x,y)
 local v = 0x6000 + y*64 + flr(x/2)
 return v
end

function glitch_vertical(x,y,hight,dis,direction)
 local xy = {}
 for i=1,hight do
  add (xy,xy_to_mem(x,y)+64-i*64)
 end 
 local d = direction or 1
 for i=hight,1,-1 do
  local xydest=xy[i]-(dis*64)
  glitch_line(xy[i],xydest,2) 
 end
end

function glitch_line(source,dest,range)
 memcpy(dest,source,range)
end

function horizon_grid() --by electricgryphon
			w=127
			n=10
			local mod=64
   gridcolor=1
   
			grid_t-=0.30
			for i=0,n do
				local z=(i*n+grid_t%n)
				local y=w*n/z+25
				line(0,y,w,y,gridcolor)
				v=i+grid_t%n/n-n/2
				line(v*9+mod,40,v*60+mod,w,gridcolor)
			end
			
			rectfill(0,0,127,39,0)
			line(0,40,127,40,1)
end

--extended key handler
function is_held(k) return band(keys[k], 1) == 1 end
function is_pressed(k) return band(keys[k], 2) == 2 end
function is_released(k) return band(keys[k], 4) == 4 end

function upd_key(k)
if keys[k] == 0 then
if btn(k) then keys[k] = 3 end
elseif keys[k] == 1 then
if btn(k) == false then keys[k] = 4 end
elseif keys[k] == 3 then
if btn(k) then keys[k] = 1
else keys[k] = 4 end
elseif keys[k] == 4 then
if btn(k) then keys[k] = 3
else keys[k] = 0 end
end
end

function init_keys()
for a = 0,5 do keys[a] = 0 end
end

function upd_keys()
for a = 0,5 do upd_key(a) end
end

function centerprint(string,y,col)
 print(string,64-#string*2,y,col)
end 

---textbox 
function tbx_init()
tbx_counter=1
tbx_width=tbx_width or 23 --characters not pixels
tbx_lines={}
tbx_cur_line=1
tbx_com_line=0
tbx_text=nil
tbx_x=nil
tbx_y=nil
end


function tbx_update()
 if tbx_text!=nil then 
 local first=nil
 local last=nil
 local rows=flr(#tbx_text/tbx_width)+2
 
 --split text into lines
 for i=1,rows do
  first =first or 1+i*tbx_width-tbx_width
  last = last or i*tbx_width
   
  --cut off incomplete words
  if sub(tbx_text,last+1,last+1)!="" or sub(tbx_text,last,last)!=" " and sub(tbx_text,last+1,last+1)!=" " then
   for j=1,tbx_width/2 do
    if sub(tbx_text,last-j,last-j)==" " and i<rows then
     last=last-j
     break
    end
   end
  end
  
  --create line
  --if first char is a space, remove the space
  if sub(tbx_text,first,first)==" " then
   tbx_lines[i]=sub(tbx_text,first+1,last)
  else
   tbx_lines[i]=sub(tbx_text,first,last)
  end
   first=last
   last=last+tbx_width
 end
 
 --lines are now made
 
 
 --change lines after printing
 if tbx_counter%tbx_width==0 and tbx_cur_line<#tbx_lines then
  tbx_com_line+=1
  tbx_cur_line+=1
  tbx_counter=1  
 end
 
 --update text counter
 if frame_num%2==0 then
  tbx_counter+=1
  if tbx_counter < #tbx_text and tbx_cur_line<#tbx_lines
  and (sub(tbx_text,tbx_counter,tbx_counter)!=" ")
  then
   sfx(1)
  end
  if (sub(tbx_text,tbx_counter,tbx_counter)=="") tbx_counter+=1
 end
 end
end


function tbx_draw()
 if #tbx_lines>0 then
  --print current line one char at a time
  print(sub(tbx_lines[tbx_cur_line],1,tbx_counter),tbx_x,tbx_y+tbx_cur_line*8-8,tbx_col)
 
  --print complete lines
  for i=0,tbx_com_line do
   if i>0 then
    print(tbx_lines[i],tbx_x,tbx_y+i*8-8,tbx_col)
   end
  end
 end 
end


function textbox(text,x,y,col,w)
 tbx_init()
 tbx_x=x or 4
 tbx_y=y or 4
 tbx_col=col or 7
 tbx_width = w or tbx_width
 tbx_text=text
end





--xxxend

function play_update()
  start_level()
  constrains()
  movepaddle()
  padspeed_down()
  serve_help()
  serve()
  wallbounce()
  hitball()
  foreach (bugs,breed_update)
  moveball ()
  lose()
  col_bugball()
  trail_update()
  bonus_update()
  timer_update()
  end_level()
  flash_square_update() 
  
 --test  
 if btnp(5) then bugmix() end
end


function play_draw()
  --clear the screen
   cls()
   camera(0,0+camoffset)
   if not level_transit then grid_draw() else horizon_grid() end  
   map(0,0,0,0,16,16)
   timer_draw()
   foreach (bugs,draw_bug)
  --draw the score
   print(score,4,8,12)
   print(lives,95,8,12)
  --draw the paddle
   rect (padx,pady,padx+padw,pady+padh,padcol)
   line (padx,pady+padh+1,padx+padw,pady+padh+1,1)
   --when game is played
   trail_draw()
   explosion_draw()
   flash_square_draw()
   bonus_draw()
   lose_check()
   serve_line()   
end

---------

function end_update()
  frame_col = 8   frame_action = 1
  endscore=score.." bytes recovered"
  local ly=flr(rnd(128))
  glitch_line_random(true)
  if (frame_num%3==0) line(ly,0,ly,127,0)
  if frame_num%30+flr(rnd(10))==0 then
   tot4=10
  end
  if is_pressed(4) then
   tot1=11
   sfx(8)
  end
  if tot1==1 then
   _init()
  end
    
end


function end_draw()
  if frame.r1 < 20  then
   centerprint ("error:connection lost",40,flash2colors(8,2,10))
   centerprint (endscore,88,8)
  end 
 explosion_draw()
end

--------
 
function intro_update()
  
  if frame_num==5 then
   textbox("connection:stable  data integrity:fail malware found:".. #bosses.. " navigate:”/ƒ    info:Ž/—",4,57,12,21)
  end
  
  if is_pressed(5) or is_pressed(4) then
   textbox(bosses[bosses.select].inf,4,57,12,21)
  end
  --boss selector
  if (is_pressed(2)) bi.y-=8 bosses.select-=1
  if (is_pressed(3)) bi.y+=8 bosses.select+=1
  if (is_pressed(2)) sfx(4)
  if (is_pressed(3)) sfx(4)
  if (bi.y< 55) bi.y=55+8*(#bosses-1) bosses.select=#bosses
  if (bi.y> 55+8*(#bosses-1)) bi.y=55 bosses.select=1
  
  --game start
 if btn(4) and btn(5) then
  tot1=11
  music(-1)
  sfx(17)
 end
 if tot1==11 then
  gamestate=1
  tbx_init()
 end
  
 if frame_num%(flr(rnd(30)+40))==0 then
  create_explosion (122,54,7,rnd(4)+2,2,rnd(10)+2)
  if rnd(1)<0.5 then 
   tot3=3
  else
   tot4=15
  end
  create_pixelfall (122,54,7,1,1)   
 end  
end


function intro_draw()
 cls()
 horizon_grid()
 if frame_num%4>2 then
  for i=1,40,2 do
   line(83,52+i,122,52+i,1) 
  end
 end
 --boss selector
 for i=1,#bosses do
   print(bosses[i].name,87,49+i*8,12)
 end
 rect(bi.x,bi.y,bi.x+34,bi.y+8,12)
 rect(82,52,122,90,12)
 for i=0,#bosses-1 do
  rect(97+i*7,93,101+i*7,97,1) 
 end  
 map(16,0,0,-4,16,16)
 spr(136,117,52)
 spr(2,61,11)   
 centerprint ("press Ž and — to access  ",112,flashbw)
 centerprint (bosses[bosses.select].name.." infected sectors",118,flashbw)
 explosion_draw()
end 
 
function _update()
 upd_keys()
 screenshake()
 frame_num+=1
 frame_control()
 explosion_update()
 if frame_num > 3000 then frame_num=1 end
 if gamestate==0 then
  intro_update()
 elseif gamestate==1 then
 	play_update()
 elseif gamestate==1.5 then	
  end_update() 
 end
 flashbw=flash2colors(12,7,6)
 flashrw=flash2colors(8,7,4)
 tbx_update()
end


function _draw()
 if gamestate==1 then
  play_draw()
 end
 if gamestate==0 then
  intro_draw()
 end
 glitch_noise() 
 if (glitch_line_factor > 0) glitch_line_random()
 frame_draw()
 if gamestate==1.5 then 
  end_draw()
 end
 tbx_draw()
 glitch_listener_draw()
end 


__gfx__
00000000fc1fffff0ccc1ffff1ccc1ffff5555ffff5555ffff5555ffff5555ff0000000000000000000000000000000000000000000000000000000000000000
00000000cfcfffffcfffcfff166ffc1fff5885ffff5885ffff5885ffff5885ff0000000000000000000000000000000000000000000000000000000000000000
000000001c1fffffcff1cfffc6ffffcfff5005ffff5005ffff5005ffff5005ff0000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffc111cfffcffff1cfff5555ffff55558fff5555fff85555ff0000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff1ccc1fffcfff11cff850058ff8555158f850058f8515558f0000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffffffff1c111c1f85f55f5885ffff5585f55f5855ffff580000000000000000000000000000000000000000000000000000000000000000
00000000fffffffffffffffff1ccc1ff55ffff5555fffff555ffff555fffff550000000000000000000000000000000000000000000000000000000000000000
00000000ffffffffffffffffffffffff5ffffff55fffffff5ffffff5fffffff50000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f88888888888888f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f80000000000008f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f80000000000008f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f80000000000008f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f80000000000008f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f88888888888888f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f22222222222222f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f99999999999999f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f90000000000009f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f90000000000009f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f90000000000009f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f90000000000009f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f99999999999999f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f44444444444444f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fddddddddddddddf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fd000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fd000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fd000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fd000000000000df0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
fddddddddddddddf0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f55555555555555f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001010000101111010111cccc0c01c0c001101cccccccccccccccccccccccccccccccccccccccccccccccccc1010110101000c01010100000000ccc01110000
000000001010101000000001010c11c1c11c0ccc111111111111111111111111111111111111111111111111cc0110c0c0c0ccc0c0c0c000c0c000000c0c0100
0001111110111111ccc111cc0c0c01c0c00000c10000000000000000000000000000000000000000000000001cccc01110010010c0c0c00ccccccccc00000000
11cccccccccccccc111ccc000001ccc0c00111c10000000000000000000000000000000000000000000000001c00ccccccccccc0c0c0c00011101110cccc0100
c1c0000001cc11c0000010000c000110c1ccccc10000000000000000000000000000000000000000000000001c00c0101011111ccccccc01ccc0ccc1000cc001
c0000c0c010001001011110100010010c00000c10000000000000000000000000000000000000000000000001cccc0101010000111111101c0c1c0c10101c100
100cccccccccccccccccccccc10cccc1111c0cc10000000000000000000000000000000000000000000000001c111ccccccc01000c0c1101ccc0ccc10101c101
00c1111111111111111111111ccc10c0001c0cc10000000000000000000000000000000000000000000000001c101c11111c010101001100111011100101c100
11c1000000000000000000001c1c11c0101000c10000000000000000000000000000000000000000000000001c111c10001ccccc11111001ccc1ccc10cccc111
c0c1000000000000000000001c1cccc0001cccc10000000000000000000000000000000000000000000000001ccccc10001c000000001101c0c0c0c10000c001
11c1000000000000000000001c111011cc1000c10000000000000000000000000000000000000000000000001c110c10001cccccccc01001ccc1ccc101ccc111
c0c1000000000000000000001c101010c00cccc10000000000000000000000000000000000000000000000001ccccc10001c00000000000011101110c100c001
11c1000000000000000000001c1011ccc01000c10000000000000000000000000000000000000001000000001c010c10001c1ccccccc0c0c010001000000cc0c
00c1111111111111111111111cccccc0c0101cc11111111111111111111111111111111111111111111111111c010c11111c01000c0c000001000100c111c011
c01cccccccccccccccccccccc100c0ccc01010cccccccccccccccccccccccccccccccccccccccccccccccccccc111ccccccc01010ccc0c0c11c0c110c100cc0c
cc0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000001111111111111111c10cc011
1011ccc1c110c0ccccccc011cccc00c0101c11c11c001000010c0cc1c1011010000111c1c1110000000001c11100000000000000011000000000000000000000
cc10c0c100c1c0c0001cc001c01011001c1cccc11c0cc110100c01c1c1000000000000c1c1010000000000c1c100000000010110000000000000000000000000
c111c0c101c1c1cccc1000c1c01001c01c1011c11c1cc010101c0cc1cc101110000111c1c111000000000111c100000000000110010000000000000000000000
c1c0ccc1c1c10c10cc10c0c1ccc0c1c01111c0c11c010010011001c1c0000100000010c1c0000000000010c11000000000000000000000000000000000000000
11c00001c1c10c1c1c1000c1c01111c011ccccc1c11c01100001ccc1cc110110000010c1c111000000011011c100000000000100101000000000000000000000
11c1ccc1c1010c110011c1c1c0c1c1c0111010c1cccc1100010001c1c0000100000000c1c0100000000110c1c100000000000000001000000000000000000000
c1c0c0c1ccc10c11c0000011ccc0ccc0111cccc1c11001000001ccc1ccc10000000011c1c0100000000010111110000000001010100100000000000000000000
11c1ccc1c1010c1ccc11c111c0c0c1c0110c00c1c11c010001001cc1c1000100000010c1c0000000000001c1c100000000010000100000000000000000000000
c11c0001c101c11c01010101c0ccc1c000110cc1cc10011000001cc1ccc10000000000c1c100000000001101c000000000000100001000000000000000000000
111c0cc1cc01c011c1c1ccc1c011c110000c1cc1c11c0000011111c1cc100100000001c1c1000000000011c1c100000000101000100000000000000000000000
ccc00001c1010ccc00c0c1c1c0c1c1c0110001c1c1011100000100c1cc100000000001c1c1100000000000110000000000000010000000000000000000000000
10c001c1c1c1c1c0c1ccccc1c01111c0010cc1c1c1cc100000110cc1c1111100000000c1c1000000000100111100000000011000101100000000000000000000
11c1c101c101011110c01011c0c1c110000cc11110cc1010000111c1c0010000000011c1c000000000011c01c110000001011010001100000000000000000000
10c001010111c1c0ccc01011c00c1cc0010100c110010010000000c1cc011000000000c1c1000000000000c1c000000001000000100000000000000000000000
ccc1c111c0ccc0c011c1ccc11c0c1c10000c0c111cc10110000111c1c1110000000000c1c1000000000011c1c000000000001010001000000000000000000000
10100011c0c0c101ccc1c0011c1c1c10111c1c111c010000000101c1c0000000000001c1c0000000000011011100000001011010101010100000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccc7cf100000000000000000000000000000000000000000000000000000000
fcccccccccccccccccccfffffffffccccccffccccccccccccccccccccccccffffffff7ff00000000000000000000000000000000000000000000000000000000
fc000000000000000000ccfffffffc0000cffc0000000000000000000000cffffffff0cf00000000000000000000000000000000000000000000000000000000
fc00000000000000000000cffffffc0000cffc0000000000000000000000cffffffff7ff00000000000000000000000000000000000000000000000000000000
fc000000000000000000000cfffffc0000cffc0000000000000000000000cffffffffcfc00000000000000000000000000000000000000000000000000000000
fc000000000000000000000cfffffc0000cffc0000000000000000000000cffffffffcff00000000000000000000000000000000000000000000000000000000
fc0000cccccccccccc000000cffffc0000cffcccccccccc0000ccccccccccffffffffc1f00000000000000000000000000000000000000000000000000000000
fc0000cfffffffffffc00000cffffc0000cfffffffffffc0000cfffffffffffffffffcff00000000000000000000000000000000000000000000000000000000
fc0000cffffffffffffc0000cffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cffffffffffffc0000cffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cfffffffffffc00000cffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cffccccccccc000000cffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cffc0000000000000cfffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cfffc00000000000cffffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fc0000cffffc0000000000cffffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
ffc000cfffffc0000000000cfffffc0000cfffffffffffc0000cffff000000000000000000000000000000000000000000000000000000000000000000000000
fffc00cffffffccccc000000cffffc0000cfffffffffffc0000cffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffc0cfffffffffffc00000cffffc0000cfffffffffffc0000cffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
fffffccffffffffffffc0000cffffc0000cfffffffffffc0000cffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
fffffffffffffffffffc0000cffffc0000cfffffffffffc0000cffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffffffffffffffffc00000cffffc0000cfffffffffffc0000cffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
fccccccccccccccccc000000cffffc0000cfffffffffffc0000cffff7777fff777ff77777f7fff7f000000000000000000000000000000000000000000000000
fc000000000000000000000cfffffc0000cfffffffffffc0000cffff7ff7fff7f7ff7fffff7fff7f000000000000000000000000000000000000000000000000
fc000000000000000000000cfffffc0000cfffffffffffc0000cffff77777f77777f77777f77777f000000000000000000000000000000000000000000000000
fc00000000000000000000cffffffc0000cfffffffffffc0000cffff77ff7f77ff7ffff77f77ff7f000000000000000000000000000000000000000000000000
fc000000000000000000ccfffffffc0000cfffffffffffc0000cf77f77ff7f77ff7f7ff77f77ff7f000000000000000000000000000000000000000000000000
fcccccccccccccccccccfffffffffccccccfffffffffffccccccf77f77777f77ff7f77777f77ff7f000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0001010000101111010111cccc0c01c0c001101cccccccccccccccccccccccccccccccccccccccccccccccccc1010110101000c01010100000000ccc01110000
000000001010101000000001010c11c1c11c0ccc111111111111111111111111111111111111111111111111cc0110c0c0c0ccc0c0c0c000c0c000000c0c0100
0001111110111111ccc111cc0c0c01c0c00000c10000000000000000000000000000000000000000000000001cccc01110010010c0c0c00ccccccccc00000000
11cccccccccccccc111ccc000001ccc0c00111c1000000000cc0ccc00cc0ccc00cc0ccc00000cc00000000001c00ccccccccccc0c0c0c00011101110cccc0100
c1c0000001cc11c0000010000c000110c1ccccc100000000c000c000c0000c00c0c0c0c000000c00000000001c00c0101011111ccccccc01ccc0ccc1000cc001
c0000c0c010001001011110100010010c00000c100000000ccc0cc00c0000c00c0c0cc0000000c00000000001cccc0101010000111111101c0c1c0c10101c100
100cccccccccccccccccccccc10cccc1111c0cc10000000000c0c000c0000c00c0c0c0c000000c00000000001c111ccccccc01000c0c1101ccc0ccc10101c101
00c1111111111111111111111ccc10c0001c0cc100000000cc00ccc00cc00c00cc00c0c00000ccc0000000001c101c11111c010101001100111011100101c100
11c1ccc0ccc00000000000001c1c11c0101000c10000000000000000000000000000000000000000000000001c111c1c0c1ccccc11111001ccc1ccc10cccc111
c0c1c00000c00000000000001c1cccc0001cccc10ccccccccccccccccccccccccccccccccccccccccccc00001ccccc1c0c1c000000001101c0c0c0c10000c001
11c1ccc00cc00000000000001c111011cc1000c10ccccccccccccccccccccccccccccccccccccccccccc00001c110c1ccc1cccccccc01001ccc1ccc101ccc111
c0c100c000c00000000000001c101010c00cccc10ccccccccccccccccccccccccccccccccccccccccccc00001ccccc100c1c00000000000011101110c100c001
11c1ccc0ccc00000000000001c1011ccc01000c10000000000000000000000000000000000000000000000001c010c100c1c1ccccccc0c0c010001000000cc0c
00c1111111111111111111111cccccc0c0101cc11111111111111111111111111111111111111111111111111c010c11111c01000c0c000001000100c111c011
c01cccccccccccccccccccccc100c0ccc01010cccccccccccccccccccccccccccccccccccccccccccccccccccc111ccccccc01010ccc0c0c11c0c110c100cc0c
cc0111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000001111111111111111c10cc011
1011ccc10888888888888881000000000000000108888888888888810000000000000001099999999999999100000000000000010999999999999991c110c0cc
cc10c0c1080080008000008100000000000000010800000008008081000000000000000109900000000009910000000000000001090000000900009100c1c0c0
c111c0c1080008800080088100000000000000010800808000800081000000000000000109000009009000910000000000000001090090009090099101c1c1cc
c1c0ccc10880000000000081000000000000000108000008000800810000000000000001090000000000009100000000000000010990090000900091c1c10c10
11c000010800000800080881000000000000000108808000000000810000000000000001090090000090009100000000000000010900000090000091c1c10c1c
11c1ccc10888888888888881000000000ccccccccccccccccccc888100000cccccc00cccccccccccccccccccccccc000000000010999999999999991c1010c11
c1c0c0c10222222222222221000000000c000000000000000000cc2100000c0000c00c0000000000000000000000c000000000010444444444444441ccc10c11
11c1ccc10000000000000001000000000c00000000000000000000c100000c0000c00c0000000000000000000000c000000000010055550000000001c1010c1c
c11c00010888888888888881000000000c000000000000000000000c00000c0000c00c0000000000000000000000c000000000010058850000000001c101c11c
111c0cc10800000000080081000000000c000000000000000000000c00000c0000c00c0000000000000000000000c000000000010050050000000001cc01c011
ccc000010800800000808081000000000c0000cccccccccccc000000c0000c0000c00cccccccccc0000cccccccccc000000000010855550000000001c1010ccc
10c001c10800000880008081000000000c0000c10000000000c00000c0000c0000c00001000000c0000c000100000000000000018515558000000001c1c1c1c0
11c1c1010808800088800081000000000c0000c100000000000c0000c0000c0000c00001000000c0000c000100000000000000015500005800000001c1010111
10c001010888888888888881000000000c0000c100000000000c0000c0000c0000c00001000000c0000c0001000000000000000150000055000000010111c1c0
ccc1c1110222222222222221000000000c0000c10000000000c00000c0000c0000c00001000000c0000c000100000000000000010000000500000001c0ccc0c0
101000111111111111111111111111111c0000c11ccccccccc000000c1111c0000c11111111111c0000c111111111111111111111111111111111111c0c0c101
ccccc0110888888888888881000000000c0000c10c0000000000000c00000c0000c00001000000c0000c000109999999999999910000000000000001cccc00c0
001cc0010800000008000081000000000c0000c100c00000000000c100000c0000c00001000000c0000c000109000000000000910000000000000001c0101100
cc1000c10880000000008081000000000c0000c1000c0000000000c100000c0000c00001000000c0000c000109090000009000910000000000000001c01001c0
cc10c0c108000008008000810000000000c000c10000c0000000000c00000c0000c00001000000c0000c000109900009000900910000000000000001ccc0c1c0
1c1000c1080000000000008100000000000c00c100000ccccc000000c0000c0000c00001000000c0000c000109099900090009910000000000000001c01111c0
0011c1c10888888888888881000000000000c0c10000000000c00000c0000c0000c00001000000c0000c000109999999999999910000000000000001c0c1c1c0
c000001102222222222222210000000000000cc100000000000c0000c0000c0000c00001000000c0000c000104444444444444410000000000000001ccc0ccc0
cc11c1110000000000000001000000000000000100000000000c0000c0000c0000c00001000000c0000c000100000000000000010000000000000001c0c0c1c0
01010101088888888888888100000000000000010000000000c00000c0000c0000c00001000000c0000c000100000000000000010888888888888881c0ccc1c0
c1c1ccc10880000000800881000000000ccccccccccccccccc000000c0000c0000c00001000000c0000c000177770007770077777878007800000081c011c110
00c0c1c10800000000000881000000000c000000000000000000000c00000c0000c00001000000c0000c000170070007070070010870807000080081c0c1c1c0
c1ccccc10808000008000881000000000c000000000000000000000c00000c0000c00001000000c0000c000177777077777077777877777000008081c01111c0
10c010110808080800080081000000000c00000000000000000000c100000c0000c00001000000c0000c000177007077007000077877007000800881c0c1c110
ccc010110888888888888881000000000c000000000000000000cc0100000c0000c00001000000c0000c077177007077007070077877887888888881c00c1cc0
11c1ccc10222222222222221000000000ccccccccccccccccccc000100000cccccc00001000000cccccc0771777770770070777772772272222222211c0c1c10
ccc1c00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111c1c1c10
101c11c100000000000000010000000000000001099999999999999108888888888888810000000000000001000000000000000100000000000000011c001000
1c1cccc100000000000000010000000000000001090900000090909108800080008080810000000000000001000000000000000100000000000000011c0cc110
1c1011c100000000000000010000000000000001090009090009009108000000080080810000000000000001000000000000000100000000000000011c1cc010
1111c0c100000000000000010000000000000001090099090090009108800000008888810000000000000001000000000000000100000000000000011c010010
11ccccc10000000000000001000000000000000109000000000090910800000088008081000000000000000100000000000000010000000000000001c11c0110
111010c10000000000000001000000000000000109999999999999910888888888888881000000000000000100000000000000010000000000000001cccc1100
111cccc10000000000000001000000000000000104444444444444410222222222222221000000000000000100000000000000010000000000000001c1100100
110c00c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c11c0100
00110cc10000000000000001000000000000000100000000000000010888888888888881000000000000000100000000000000010000000000000001cc100110
000c1cc10000000000000001000000000000000100000000000000010800000088080081000000000000000100000000000000010000000000000001c11c0000
110001c10000000000000001000000000000000100000000000000010800080000000081000000000000000100000000000000010000000000000001c1011100
010cc1c10000000000000001000000000000000100000000000000010808088880808081000000000000000100000000000000010000000000000001c1cc1000
000cc111000000000000000100000000000000010000000000000001080008080080008100000000000000010000000000000001000000000000000110cc1010
010100c1000000000000000100000000000000010000000000000001088888888888888100000000000000010000000000000001000000000000000110010010
000c0c1100000000000000010000000000000001000000000000000102222222222222210000000000000001000000000000000100000000000000011cc10110
111c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111c010000
010c0cc10999999999999991000000000000000100000000000000010000000000000001000000000000000100000000000000010999999999999991c1011010
100c01c10900000000090091000000000000000100000000000000010000000000000001000000000000000100000000000000010900900000000991c1000000
101c0cc10900090000000091000000000000000100000000000000010000000000000001000000000000000100000000000000010909000009909991cc101110
011001c10900000000000091000000000000000100000000000000010000000000000001000000000000000100000000000000010900990009000091c0000100
0001ccc10900009000000091000000000000000100000000000000010000000000000001000000000000000100000000000000010900009000000091cc110110
010001c10999999999999991000000000000000100000000000000010000000000000001000000000000000100000000000000010999999999999991c0000100
0001ccc10444444444444441000000000000000100000000000000010000000000000001000000000000000100000000000000010444444444444441ccc10000
01001cc10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000100
00001cc10000000000000001000000000000000108888888888888810000000000000001088888888888888100000000000000010000000000000001ccc10000
011111c10000000000000001000000000000000108808000080000810000000000000001080000088808008100000000000000010000000000000001cc100100
000100c10000000000000001000000000000000108880000000008810000000000000001080080000000008100000000000000010000000000000001cc100000
00110cc10000000000000001000000000000000108800000000000810000000000000001080000000808808100000000000000010000000000000001c1111100
000111c10000000000000001000000000000000108000008000000810000000000000001080000000880088100000000000000010000000000000001c0010000
000000c10000000000000001000000000000000108888888888888810000000000000001088888888888888100000000000000010000000000000001cc011000
000111c10000000000000001000000000000000102222222222222210000000000000001022222222222222100000000000000010000000000000001c1110000
000101c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111c0000000
000111c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1110000
000000c10000000000000001000000000000000100000000ccc100010000000000000001000000000000000100000000000000010000000000000001c1010000
000111c1000000000000000100000000000000010000000c000c00010000000000000001000000000000000100000000000000010000000000000001c1110000
000010c1000000000000000100000000000000010000000c001c00010000000000000001000000000000000100000000000000010000000000000001c0000000
000010c1000000000000000100000000000000010000000c111c00010000000000000001000000000000000100000000000000010000000000000001c1110000
000000c10000000000000001000000000000000100000001ccc100010000000000000001000000000000000100000000000000010000000000000001c0100000
000011c100000000000000010000000000000001000000000c0000010000000000000001000000000000000100000000000000010000000000000001c0100000
000010c100000000000000010000000000000001000000c0000000010000000000000001000000000000000100000000000000010000000000000001c0000000
000000c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000001c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000001c1000000000000000100000000000000010000c000000000010000000000000001000000000000000100000000000000010000000000000001c1100000
000000c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000011c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c0000000
000000c10000000000000001000000000000000100010000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000000c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000001c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111c0000000
000001c1000000000000000100000000000000010100000000000001000000000000000100000000000000010000000000000001000000000000000111000000
000000c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000001110000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000010c1000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000110000000
000110110000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000110c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
00001011000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000111100000
000001c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
000011010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c0000000
000011c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1000000
00000011000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000
00010011000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000111000000
00011c010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c1100000
000000c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c0000000
000011c10000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001c0000000
00001101111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000000
00000000000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000101100000
00010110000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000
00000110000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000101000000
00000000000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000
00000100000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000110100000
00000000000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100100000
00001010000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000110010000
00010000000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000110000000
00000100000000000000000100000000000000010000000000000001000000000cccccccccccccccccccccccc000000000000001000000000000000100100000
00101000000000000000000100000000000000010000000000000001000000000c0000010000000000000001c000000000000001000000000000000110000000
00000010000000000000000100000000000000010000000000000001000000000c0000010000000000000001c000000000000001000000000000000100000000
00011000000000000000000100000000000000010000000000000001000000000c0000010000000000000001c000000000000001000000000000000110110000
01011010000000000000000100000000000000010000000000000001000000000cccccccccccccccccccccccc000000000000001000000000000000100110000
01000000000000000000000100000000000000010000000000000001000000000111111111111111111111111000000000000001000000000000000110000000
00001010000000000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100100000
01011010111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110101010

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
40414243444545454545454b4c4d4e4f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505152535455555555555a5b5c5d5e5f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6000000000000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000000000000000000000000007100000000808182838485868700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6200000000000000000000000000006300000000909192939495960000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7200000000000000000000000000007300000000a0a1a2a3a4a5a6a7a8a90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6400000000000000000000000000006500000000b0b1b2b3b4b5b6b7b8b90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7400000000000000000000000000007500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6600000000000000000000000000006700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7600000000000000000000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6800000000000000000000000000006900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7800000000000000000000000000007900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6a00000000000000000000000000006b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7a00000000000000000000000000007b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6c00000000000000000000000000006d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7c00000000000000000000000000007d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01040000196500c640196500c650196000c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01040000323552d355000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
010400001965019655196001960019600196001960019600006000060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001000021655124551245511455104550f4550e4350c4250b4250942508425064150441503415024150241500005000050000500005000050000500005000050000500005000050000500005000050000500005
00010000254501c4501945016450124500f4500d4400c4400a4400943007430054300442001420014100000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0106000010670184501c6700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0105000024175281752b1753017500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000301752b17528175231753010029100241001f1002f10028100211001a1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00003217432170110000e0000c00010000100000e0001000011000130001800018000180001300013000130001000010000100000c0000c0000c0001300011000100000e0000c00000000000000000000000
00100000181751f175241751f17524175291752340025400284002a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011800000c3720c3720c3720c3521b3000c3720c3720c3720c352173000c3720c3720c3720c352000000c3720c3720c3720c35200000000000000000000000000000000000000000000000000000000000000000
012000000c3741b374133740f3740c3741b374133740f3740c3741b374133740f3740c3741b374133740f3740c3741b374133740f3740c3741b374133740f3740c3741b374133740f3740c3741b3740f3740c374
002000000c4720f4020f4720c40211472104020f4720e4020c4720e4020c4020f4020c4020c4020c4020f4020f47211402114720f4020f4720c4020c4720c4020c4720c402114020f4020c4020e4020c40210402
00200000114720f4020f4720c40211472104020f4720e402114720e4020f472104020c4720c4020c4020f4020f47211402114720f4020f4720c4020c4720c4020c4720c4020c402134020c4020e4020c40210402
011000000c6450c5050c545000000c645000000f545000000c6450000011545000000c645000000f545000000c645000000c545000000c645100000c545000000c645000050f545000050c645000050c54500000
011000000c4420f4020f4420c40211442104020f4420e4020c4420e4020c4020f4020c4020c4020c4020f4020f44211402114420f4020f4420c4020c4420c4020c4420c402114020f4020c4020e4020c40210402
01100000114420f4020f4420c40211442104020f4420e402114420e4020f442104020c4420c4020c4020f4020f44211402114420f4020f4420c4020c4420c4020c4420c4020c402134020c4020e4020c40210402
001000001b3440c0041d344000041b34400004183440000418344000041833400004183240c004183140230418304000040b30400004000041300013000000040000400004000040000400004000040000400004
010f00001333000300133301d31423330153141733000300183300030017330003001533000300133300030012330003000e33000300103300e30012330003001333000300133000030013330003000030000300
000100200941604416044160441604416044160441604416044160441601416014160141601416024160241601416014160141601416034160541605416044160341603416044160341601416014160141601416
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0b424344
01 0b0c4344
02 0b0d4344
00 11524344
00 0e424344
01 0e0f4344
02 0e104344
04 11524344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

