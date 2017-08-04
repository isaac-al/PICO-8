pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--dusk child
--by sophie houlden

px=24--360--player x
py=64--150--player y
fx=0--force x
fy=0--force y
pg=0--player grounded
pf=false--flip player sprite
cring=false--crouching
dead=false
gametitle = true
fadeout=-1
super=false

cpu=0

--game progression
wopen=false
wlit=false
eopen=false
elit=false

cx=900--checkpoint x
cy=0--checkpoint y
checkwopen=false
checkwlit=false
checkeopen=false
checkelit=false
checkinv=0
--no checkpoint info for super
--put unavoidable checkpoints
--around that!!!

gameover=false

cansuper=false
cutscene=false


woff=0--world offset
yoff=0

killer=false--what killed the player
kx=0--where to draw deach circle
ky=0

spheremsg=1

texts={"","","","","","","","","",""}
texttimes={0,0,0,0,0,0,0,0,0,0}
textscroll=7

--update game object stuff
function goupdate()
for i=1,count(actors) do
 actor=actors[i]

 --save tokens!
 actype=actor.t
 acx=actor.x
 acy=actor.y
 aca=actor.a
 acb=actor.b
 acc=actor.c
 acwoff=actor.woff
 acyoff=actor.yoff

 --carried objects
  --orb and keystones
  if actype==3 or actype==9 then
   if aca==1 then
    acx=px
    acy=py
    acwoff=woff
    acyoff=yoff
   end
  end

  --bucket
  if actype==4 then
   lastc=acc
   if acc>0 and aca==1 then
    acc-=0.4
    dropcol=7
    if(rnd()>0.4)dropcol=12
    addpart(2,px+rnd()*2,py-7+rnd()*2,dropcol)
   end
   acb=2
   if(acc<60) acb=3
   if(acc<30) acb=4
   if(acc<=0) acb=5

   if aca==1 then
    --being carried
    acx=px-4
    acy=py-8
    acwoff=woff
    acyoff=yoff
    --if acc<60 and lastc>=60 then
     --addtext("water leaks from the bucket")
    --end
    --if acc<=0 and lastc>0 then
     --addtext("the bucket is empty")
    --end
   end

   buckettile=msget(acx+4,acy+4)
   if buckettile==20 then
    acc+=5
    if acc>50 then
     acc=100
     --if(aca==1 and lastc<97)addtext("the bucket is full")
    end
   end

   if buckettile==19 or (super and aca==1) then
    acc=0
    if(aca==1 and lastc>0)addtext("the water evaporates")
   end

  end

 if acwoff==woff and
    acyoff==yoff then

  --fire
  if actype==1 then
   lit=true
   if (actor.wlit and not wlit) lit=false
   if (actor.elit and not elit) lit=false
   if lit then
    sparkcount=5
    if(cpu>0.7)sparkcount=3
    if(cpu>0.8)sparkcount=2
    if(cpu>0.9)sparkcount=0
    for k=0,sparkcount do
     sparkcol=7
     if (rnd()>0.5) sparkcol=9
     if (rnd()>0.5) sparkcol=10
     addpart(1,acx+2+(rnd()*4),acy+8,sparkcol,acb)
    end
   end
  end

  --eyedol
  if actype==2 then

   lastc=acc
   acc=0
   for k=1,count(actors) do
    actorb=actors[k]
    if actorb.t==3 then
    if (actorb.woff==acwoff and
       actorb.yoff==acyoff) or
       k==inv then
     if(lastc==0) addtext("the orb pacifies eyedols")
     acc=1--doopy

    end
    end
   end


   ppy=py-12
   if(cring)ppy=py-4
   dist=getdist(px,ppy,acx+4,acy+4)
   lasta=aca
   aca=0
   if(dist<60) aca=1
   if(dist<40) aca=2

   if acc==1 then
     --pacified
     aca=0
     dist=500
   end

   if lasta<1 and dist<60 then
    sfx(8)
   end
   if lasta<2 and dist<40 then
    sfx(7)
    addtext("the eyedol glares at you")
   end
   if dist<40 then
    acb+=0.5
    if(flr(acb)>count(eyeflash)) acb=1
   end
   if dist<30 then
    sfx(9)
    dienow(actor)

    midx=(px-acx)*0.5
    kx=px-midx
    midy=(py-(acy+16))*0.5
    ky=py-midy

    addtext("dont anger eyedols")
   end

  end

  --sprinkler
  if actype==5 then
   dropcount=4
   if(cpu>0.7)dropcount=3
   if(cpu>0.8)dropcount=2
   if(cpu>0.9)dropcount=1

   if (acb==1 and not wopen) dropcount=0
   if (acb==2 and not eopen) dropcount=0

   for k=1,dropcount do
    dropcol=7
    if (rnd()>0.5) dropcol=13
    if (rnd()>0.5) dropcol=12
    addpart(2,acx+2+(rnd()*4),acy,dropcol)
   end
  end

  --pullyshelf
  if actype==7 then

   shelfweighted=false
   for k=1,count(actors) do
    actorb=actors[k]
    if (actorb.t==3 or
       actorb.t==9 or
       (actorb.t==4 and
       actorb.c>0)) and
       actorb.a==0 and
       actoraabb(actor,actorb) then
     shelfweighted=true
    end
   end

   if shelfweighted then
    aca=0
   else
    aca=8
   end
  end

  --pullydoor
  if actype==6 then

   dooropen=false

   if acb==0 then
   for k=1,count(actors)do
    actorb=actors[k]
    if actorb.t==7 and
       actorb.a==0 and
       actorb.woff==acwoff and
       actorb.yoff==acyoff then
     dooropen=true
    end
    if actorb.t==10 and
       actorb.a==1 and
       actorb.woff==acwoff and
       actorb.yoff==acyoff then
     dooropen=true
    end
   end
   end

   if (acb==1 and wopen) dooropen=true
   if (acb==2 and eopen) dooropen=true

   if dooropen then
    if(aca==0)sfx(10)
    aca+=1
    if(aca>16)aca=16
   else
    if(aca==16)sfx(11)
    aca-=1
    if(aca<0)aca=0
   end


   if aca==16 then
    mset(flr8(acx),flr8(acy),0)
    mset(flr8(acx),flr8(acy)-1,0)
   else
    mset(flr8(acx),flr8(acy),97)
    mset(flr8(acx),flr8(acy)-1,97)
   end
  end

  --statue
  if actype==8 then
   lightnow = false
   if super then
    x=acx
    if(aca==0)x+=24
    if pbox(px,py,x,acy-32,8,8) and
       acb==0 then
     lightnow = true
     addtext("you light the statue fire")
    end
   end
   if (aca==0 and wlit) lightnow=true
   if (aca==1 and elit) lightnow=true

   x=0
   if(aca==0)x+=3
   if not actor.unlightable then
    mset(flr8(acx)+x,flr8(acy)-4,0)
   end

   if lightnow and not actor.unlightable then
    if aca==0 then
     wlit=true
    else
     elit=true
    end
    acb=1
   end


   if acb==1 then
    for k=0,5 do
     sparkcol=7
     if (rnd()>0.5) sparkcol=9
     if (rnd()>0.5) sparkcol=10
     spx=acx+2
     if(aca==0)spx+=24
     addpart(1,spx+(rnd()*4),acy-24,sparkcol,0)
    end
    mset(flr8(acx)+x,flr8(acy)-4,19)
   end

  end

  --keystone locks
  if actype==10 and aca==0 then
   for k=1,count(actors) do
    actorb=actors[k]
    if actorb.t==9 and
       actorb.a==0 and
       actorb.x>=acx-4 and
       actorb.x<acx+12 and
       actorb.y>=acy and
       actorb.y<acy+16 then
     addtext("the keystone slots in")
     actorb.x=9999
     aca=1
     if actor.east then
      eopen=true
     else
      wopen=true
     end
    end
   end
  end

 end

 if respawning then
  acx=actor.ch_x
  acy=actor.ch_y
  aca=actor.ch_a
  acb=actor.ch_b
  acc=actor.ch_c
  acwoff=actor.ch_woff
  acyoff=actor.ch_yoff

  --addtext(i)

 end

 actor.t=actype
 actor.x=acx
 actor.y=acy
 actor.a=aca
 actor.b=acb
 actor.c=acc
 actor.woff=acwoff
 actor.yoff=acyoff

 if checkpointing then
  actor.ch_x=acx
  actor.ch_y=acy
  actor.ch_a=aca
  actor.ch_b=acb
  actor.ch_c=acc
  actor.ch_woff=acwoff
  actor.ch_yoff=acyoff

  --addtext("ch")


 end

end
--keep these outside the loop!
respawning=false
checkpointing=false
end

function flr8(v)
 return flr(v/8)
end



function bucketpal(p)
 --if p==2 then
 -- pal(11,12) pal(4,12)
 --else
 -- pal(4,5) pal(11,13)
 --end
 --if p<=3 then
 -- pal(2,12) pal(14,12)
 --else
 -- pal(2,5) pal(14,13)
 --end
 --if p<=4 then
 -- pal(8,12) pal(3,12) pal(9,12)
 --else
 -- pal(8,1) pal(3,5) pal(9,13)
 --end
end

eyeflash={11,10,10,26,27,26,10,10}
function godraw()
for i=1,count(actors) do
 actor=actors[i]
 actype=actor.t
 acx=actor.x
 acy=actor.y
 aca=actor.a

 if actor.woff==woff and
    actor.yoff==yoff then

  --draw statues
  if actype==8 and
     actor.woff==woff and
     actor.yoff==yoff then
   flippit = false
   lit=false
   if(aca==1)flippit=true
   if(actor.b==1)lit=true
   drawstatue(acx,acy,flippit,lit)
  end

  --final door
  if actype==12 then

   y=acy
   x=acx

   clip(wrap(x,128),wrap(y,112),31,32)
   rectfill(x,y,x+31,y+31,7)
   if wlit and elit then
    if px>x+12 and px<x+20 then
     actor.a+=0.1
     if not cutscene then
      addtext("the door begins to open")
     end
     cutscene=true
     py+=(actor.y+32-py)*0.2
    end
    x-=1
    x+=rnd()*2
    for i=1,3 do
     addpart(1,x+rnd()*32,y+32-min(actor.a,32),-1,0,3-cpu)--+rnd()*2)
    end
    if actor.a>=38 then--38
     gameover=true
     fadeout=16
    end
   end
   y-=actor.a
   spr(71,x,y)
   spr(71,x+8,y,2,1)
   spr(71,x,y+8,1,2)
   spr(71,x+8,y+8,2,2)
   spr(87,x,y+24)
   spr(87,x+8,y+24,2,1)
   spr(72,x+24,y)
   spr(72,x+24,y+8,1,2)
   spr(88,x+24,y+24)
   clip()

  end

  --eyedol
  if actype==2 then
   eyespr=11
   if(aca==1)eyespr=10
   if aca==2 then
    eyespr=eyeflash[flr(actor.b)]
   end
   spr(eyespr,acx-4,acy-4)
  end

  --pullydoor
  if actype==6 then
    spr(102,acx,acy-aca)
    spr(102,acx,(acy-8)-aca)
    --if (actor.b==1) spr(3,acx,acy-aca)
  end

  --pullyshelf
  if actype==7 then
    spr(57,acx,acy-aca)
    if(aca==0)spr(41,acx,(acy-8))
  end

  --keystone lock
  if actype==10 and aca==1 then
   spr(9,acx+4,acy)
  end

  --bucket
  if actype==4 and aca==0 then
    --bucketpal(actor.b)
    spr(actor.b,acx,acy)
    --spr(2,acx,acy)
    pal()
  end

  --orb
  if actype==3 and aca==0 then
    spr(actor.b,acx,acy)
  end


  --keystone
  if actype==9 and aca==0 then
    spr(9,acx,acy)
  end

  --ancient tablet
  if actype==11 then
   if not cansuper then
    if aca==0 then
     if px>acx-4 and
        px<acx+4 then
      actor.a=1
      cutscene=true
      addtext("you look up at the tablet")
     end
    end

    if actor.a>0 then
     px+=(acx+2-px)*0.2
     py+=(acy+64-py)*0.2
     actor.b+=1
     if actor.b>60 then
      actor.a+=1
      range=actor.a*4
      range+=5
      if actor.a==3 then
       addtext("and are unable to look away")
       addpart(3,acx,acy,range,0,2,5)
       addpart(3,acx,acy,range,1.5,2,4)
      end
      if actor.a==5 then
       addtext("however, you are not afraid")
       addpart(3,acx,acy,range,0,2,4)
       addpart(3,acx,acy,range,1.5,2,3)
      end
      if actor.a==7 then
       addtext("the writing almost seems...")
       addpart(3,acx,acy,range,0,2,2)
       addpart(3,acx,acy,range,1.5,2,2)
      end
      if(actor.a==9)addtext("...familiar")

      if actor.a==12 then
       addtext("you feel different")
       addtext("awakened")
       cutscene=false
       cansuper=true
      end

      actor.b=0
     end
    end

   end

   for i=1,count(parts) do

    p=parts[i]
    if p and p.t==3 then
    if cutscene then

     if actor.a+p.d>12 then
      p.fx=px
      p.fy=py-7
      p.b=min(p.b+0.002,0.2)
      p.x+=(p.fx-p.x)*p.b
      p.y+=(p.fy-p.y)*p.b
     else
      p.fy+=0.002*actor.a
      rotness=(p.fy)
      p.x=acx+sin(rotness)*p.fx
      p.y=acy+cos(rotness)*p.fx
     end

    else
     del(parts,p)
    end
    end
   end

   if actor.a>10 then
    actor.c=max(0,actor.c-0.01)
   end

   if actor.c>0 then
    fadecirc(acx,acy,(8+(sin(time*0.8)*7))*actor.c,whitefade,1)
    fadecirc(acx,acy,(7+(cos(time*0.8)*6))*actor.c,blackfade,1)
    fadecirc(acx,acy,(6+(sin((time+2)*0.8)*5))*actor.c,whitefade,1)
   end

  end



 end
end
end


function getdist(ax,ay,bx,by)
 a=ax-bx
 b=ay-by
 a*=0.01
 b*=0.01
 a=a*a+b*b
 if (a==0) return 0--avoid crash
 a=sqrt(a)*100
 --clamp huge numbers
 if(a<0) return 32767

 return a--done!
end

function wipesprite(x,y)
 for pixx=0,7 do
 for pixy=0,7 do
  sset(pixx+x,pixy+y,0)
 end
 end
end

function _init()

 --music(0)

 --hide helper gfx
 wipesprite(24,8)
 wipesprite(32,8)
 wipesprite(8,48)

 --should instantiate gameobjects here
 for x=0,160 do
 for y=0,80 do
  tilenum=mget(x,y)

  if tilenum==50 then
   --add fire
   addactor(1,x,y,19)
  end
  if tilenum==52 then
   --add downwards fire
   addactor(-1,x,y,19)
  end
  if tilenum==103 then
   --add wlit fire
   addactor(100,x,y,0)
  end
  if tilenum==104 then
   --add elit fire
   addactor(-100,x,y,0)
  end

  if tilenum==10 then
   --add eyedol
   addactor(2,x,y,-1)
  end

  if tilenum==1 then
   --add orb
   addactor(3,x,y,0)
  end

  if tilenum==2 then
   --add bucket
   addactor(4,x,y,0)
   --mset(x,y,0)
  end

  if tilenum==3 then
   --add keystone
   addactor(9,x,y,0)
  end

  if tilenum==51 then
   --add sprinkler
   addactor(5,x,y,20)
  end
  if tilenum==121 then
   --add west sprinkler
   addactor(-5,x,y,20)
  end
  if tilenum==122 then
   --add east sprinkler
   addactor(-50,x,y,20)
  end

  if tilenum==102 then
   --add pullydoor
   addactor(6,x,y,0)
  end
  if tilenum==125 then
   --add west pullydoor
   addactor(-6,x,y,0)
  end
  if tilenum==126 then
   --add east pullydoor
   addactor(-66,x,y,0)
  end

  if tilenum==57 then
   --add pullyshelf
   addactor(7,x,y,0)
   mset(x,y-1,0)
  end

  if tilenum==96 then
   --add west keystonelock
   addactor(10,x,y,48)
  end

  if tilenum==26 then
   --add east keystonelock
   addactor(-10,x,y,48)
  end

  if tilenum==92 then
   --add statue
   mset(x,y,0)
   addactor(8,x,y,97)
  end
  if tilenum==91 then
   --add flipped statue
   mset(x,y,0)
   addactor(-8,x,y,97)
  end
  if tilenum==95 then
   --add statue(unlightable)
   mset(x,y,0)
   addactor(18,x,y,97)
  end
  if tilenum==94 then
   --add flipped statue(unlightable)
   mset(x,y,0)
   addactor(-18,x,y,97)
  end

  if tilenum==113 then
   --add ancient tablet
   addactor(11,x,y,56)
  end

  if tilenum==112 then
   --final door
   addactor(12,x,y,0)
  end

 end
 end
end

actors={}
function addactor(t,x,y,replacetile)
 a={}
 a.t=t
 a.x=x*8
 a.y=y*8
 --flags
 a.a=0
 a.b=0
 a.c=0

 --offset
 a.woff=flr((x*8)/128)
 a.yoff=flr((y*8)/112)

 --east/west pullydoors
 if t==-6 then
  a.b=1
  a.t=6
 end
 if t==-66 then
  a.b=2
  a.t=6
 end

 --sprinklers
 if t==-5 or t==-50 then
  a.t=5
  if(t==-5)a.b=1
  if(t==-50)a.b=2
 end

 --remote statue fires
 if t==100 or t==-100 then
  a.t=1
  if(t==100)a.wlit=true
  if(t==-100)a.elit=true
 end

 --downwardsfire
 if t==-1 then
  a.b=1
  a.t=1
 end

 --eyedol
 if t==2 then
  a.x+=4
  a.y+=4
  a.b=1
 end

 --east keystone lock
 if t==-10 then
  a.t=10
  a.east=true
 end

 --orb
 if t==3 then
  a.b=1--inv sprite
 end

 --bucket
 if t==4 then
  a.b=2
 end

 --keystone
 if t==9 then
  a.b=9--inv sprite
 end

 --pullyshelf
 if t==7 then
  a.a=8
 end

 --ancient tablet
 if t==11 then
  a.c=1
 end

 --statues
 if t==8 or t==-8 or t==18 or t==-18 then
  a.c=a.x
  if(t==-18 or t==18) a.unlightable=true
  if t==8 or t==18 then
   a.x-=24
   a.t=8
  else
   a.t=8
   a.a=1
  end
  a.y+=8*3
 end

 --checkpoint values
 a.ch_x=a.x
 a.ch_y=a.y
 a.ch_a=a.a
 a.ch_b=a.b
 a.ch_c=a.c
 a.ch_woff=a.woff
 a.ch_yoff=a.yoff

 add(actors,a)

 if (replacetile != -1) mset(x,y,replacetile)
end

--conditional mset
--only replaces blank tiles
function cmset(x,y,v)
 if(mget(x,y)==0)mset(x,y,v)
end

parts={}--particles
function addpart(t,x,y,a,b,c,d)
 p={}
 p.t=t
 p.x=x
 p.y=y
 p.a=a
 p.b=b
 p.c=c
 p.d=d
 p.life=10

 if t==1 then
  --spark
  p.fx=rnd()-0.5
  p.fy=(rnd()-1.5)*0.5
  if(b==1) then
   p.y-=8
   p.fy=(rnd()*1.5)*2.5
  end
  p.life=rnd()*15
 end
 if t==2 then
  --drop

  p.fx=(rnd()-0.5)*0.5
  p.fy=0
  p.life=50
  p.c=a
 end

 if t==3 then
  --glow
  p.fx=a
  p.fy=b
  p.a=c
  p.b=0
 end

 add(parts,p)
end

function doparticles()
clip(0,0,127,112)
for i=1,count(parts) do
part = parts[i]
if part then
  --sparks
 if part.t==1 then
  part.x+=part.fx
  part.y+=part.fy
  part.fy-=0.1
  part.fx*=0.9
  part.life-=1*(1+part.fx)
  if part.a>=0 then
   if(part.life<3)part.a=5
   pset(part.x,part.y,part.a)
  else
   fadecirc(part.x,part.y,part.c,whitefade,1)
  end
 end

 --drops
 if part.t==2 then
  lastx=part.x
  lasty=part.y
  part.x+=part.fx
  part.y+=part.fy

  if msget(part.x,part.y)>=64 then-- or
   --drop hit solid ground or player
   part.fy*=-0.3
   part.fx=(rnd()-0.5)*5*part.fy
   part.x=lastx
   part.y=lasty
   if msget(part.x,part.y+4)>=64 then
    while msget(part.x,part.y)<64 do-- and
     part.y+=1
    end
   else
    --probably a wall hit
    part.fx*=-0.8
   end
   part.y-=1
   part.life*=rnd()
  end

  part.fy+=0.1
  part.fx*=0.9
  part.life-=1

  line(lastx,lasty,part.x,part.y,part.a)
 end

 --glow
 if part.t==3 then
  fadecirc(part.x,part.y,part.c,whitefade,1)
  if cpu<0.8 then
   addpart(1,part.x,part.y,-1,0,2-cpu)--+rnd()*2)
  end
 end

 if part.life<0 then
  del(parts,part)
 end

end
end
clip()
end

inv=0--inventory

aniframe=1--current anim frame
anitime=0--timer for anim frames

idle={16}
walk={17,18}
duck={19}
crawl={19,20}
rise={21}
fall={22}

time=0

function _update()
 time+=0.033
 if(fadeout>=0)return

 if(gameover)return

 if gametitle then
  if btn(4) or btn(5) then
   --start game
   addtext(" ")
   addtext(" ")
   addtext("you finally arrive...")
   addtext("why were you drawn here?")

   --music(-1)
   sfx(1)
   fadeout=16
  end
  return
 end

 if(dead) respawnnow()

 goupdate()

 --input
 if (cutscene) return

 if(btn(0)) fx-=0.4 pf=true
 if(btn(1)) fx+=0.4 pf=false

 if collides(px,py+1)!=true then
  --not grounded
  pg=0
  fy+=0.2
  if(canstand())cring=false
 else
  --grounded
  if (pg!=1)sfx(5)
  pg=1

  if (canstand()) cring=false
  if (btn(3)) cring=true

  if btnp(2) and not cring then
   fy=-3.5--jump!
   sfx(4)
  end
 end

 --forces
 if fx>0 then
  fx=max(fx-0.2,0)
 else
  fx=min(fx+0.2,0)
 end
 fx=mid(-2,fx,2)
 fy=mid(-5,fy,2)
 if cring then
  fx=mid(-1,fx,1)
 end

 --move player
 moveplayer()


 ancl=true --action not claimed yet

 actionbtn=btnp(4)

 --pick up actors
 if actionbtn and pg==1 and ancl then
 for i=1,count(actors) do
  actor = actors[i]
 if pbox(px,py,actor.x,actor.y,8,16) then

  --orb
   if actor.t==3 and actor.a==0 and ancl then
    if (inv!=0) dropitem()
    addtext("you pick up the orb")
    inv=i
    actor.a=1
    ancl=false
   end

  --keystone
   if actor.t==9 and actor.a==0 and ancl then
    if (inv!=0) dropitem()
    addtext("you pick up the keystone")
    inv=i
    actor.a=1
    ancl=false
   end

  --bucket
   if actor.t==4 and actor.a==0 and ancl then
    if (inv!=0) dropitem()
    addtext("you pick up the bucket")
    if actor.c<=0 then
     addtext("it has a hole in the base")
    else
     addtext("water starts to leak from it")
    end
    inv=i
    actor.a=1
    ancl=false
   end

 end
 end

  --put down actors
 --inventory management
  if ancl and inv!=0 then
    dropitem()
  end
 end



 --map interactions
 ptile1=pmsget()
 ptile2=pmsget(9)
 if actionbtn and pg==1 and ancl then
  --signs
  if ptile1==62 then
   readsign(px,py)
   ancl=false
  end
  --spikes
  if ancl and
   (ptile1==30 or
      ptile1==31) then
    addtext("these look sharp...")
    ancl=false
  end
  --checkpoints
  if ancl and
     ptile2==47 then
   addtext("you see yourself reflected")
   ancl=false
  end
  --water
  if ancl and ptile1==20 then
    addtext("it's wet")
    ancl=false
  end
  --final door
  if ancl and ptile1==23 then
    addtext("a large stone door")
    ancl=false
  end
  --fire
  if ancl and ptile1==19 or
      ptile2==19 then
    addtext("the fire burns brightly")
    ancl=false
  end
  --bones
  if ancl and ptile1==15 then
    addtext("a pile of bones,")
    addtext("they look... human")
    ancl=false
  end
 end

 --static actors (switches etc)
 if actionbtn and pg==1 and ancl then
 for i=1,count(actors) do
  actor=actors[i]

  --examine statues
  if actor.t==8 and ancl then
   if pbox(px,py,actor.c,actor.y-32,8,8) then
    if actor.b==0 then
     addtext("a statue, it has some very")
     addtext("old burn marks on it's hands")
    end
    ancl=false
   end
  end

  --examine keystonelock
  if pbox(px,py,actor.x,actor.y,16,16) then
  if actor.t==10 and ancl then
   if actor.a==0 then
    addtext("a hole in the stone, looks")
    addtext("like something is missing")
   else
    addtext("the keystone is set")
    addtext("firmly in it's place.")
   end
   ancl=false
  end
  end

 if pbox(px,py,actor.x,actor.y,8,8) then

   --examine pullyshelf
   if actor.t==7 and ancl then
    addtext("a shelf attached to a pully")
    addtext("weighing it down may help?")
    ancl=false
   end



 end
 end
 end

 if actionbtn and ancl and pg==1 then
  addtext("there is nothing here")
 end

 --super power!
 if btnp(5) then
  if cansuper then
   super = not super
   if super then
    sfx(14)
   else
    sfx(13)
   end
  else
   addtext("?")
  end
 end

end

function  dropitem()
 invactor=actors[inv]
   invactor.x=px-4
   invactor.y=py-7
   invactor.a=0
   invactor.woff=woff
   invactor.yoff=yoff

   if (invactor.t==3) addtext("you put down the orb")
   if (invactor.t==9) addtext("you put down the keystone")
   if invactor.t==4 then
    addtext("you put down the bucket")
    if invactor.c>0 then
     addtext("sealing a hole in it's base")
    else
     --put down empty bucket
     for i=1,count(actors) do
     if actors[i].t==7 then
     if actoraabb(invactor,actors[i]) then
      addtext("it is too light when empty")
      invactor.y-=8
     end
     end
     end
    end

   end
   inv=0
   ancl=false
end

function readsign(x,y)
 addtext("it reads:")

 if yoff==0 then
  if woff==0 then
   addtext('"warning:')
   addtext('to step forward is to accept')
   addtext('that you may not return."')
  end
  if woff==5 then
   addtext('"keep your head down"')
   end
 end
 if yoff==2 then
  if woff==1 then
   addtext('"western temple')
   addtext('replace keystone to open"')
  end
  if woff==3 then
   addtext('"try jumping"')
  end
  if woff==4 then
   --addtext('"~ world door ~',55)
   addtext('we must leave,',55)
   addtext('but our exit stays.',55)
   addtext('...lost child, follow us!',55)
   addtext('your home must travel on,',55)
   addtext('but you may yet reach it"',55)

   --addtext('"we must leave this place',55)
   --addtext('but we do so with heavy',55)
   --addtext('hearts, for we also leave',55)
   --addtext('something most dear.',55)
   --addtext('so this door shall stay,',55)
   --addtext('that our lost child may',55)
   --addtext('follow us through it."',55)
  end
  if woff==6 then
   addtext('"eastern temple')
   addtext('replace keystone to open"')
  end
 end
 if yoff==3 then
  if woff==6 then
   addtext('"orbs pacify eyedols"')
  end
  if woff==7 then
   addtext('"vvvvvvery tricky, this one"')
   addtext("...?")
  end
 end

 --addtext(woff.."~"..yoff)
end


function moveplayer()
 fromx=px
 fromy=py

 px+=fx
 py+=fy

 --foot collision
 if collides(px,py) then
  if collides(fromx,py) then
   --collides even on old x
   --floor or ceiling collision
   px=fromx
   py=fromy
   fy=0
  else
   if collides(px,fromy) then
    --collides even on old y
    --wall collision
    fx *= -0.7
    px = fromx
   end
  end

  if collides(px,py) then
   --still collides, it was
   --a complete collision
   px=fromx
   py=fromy
   fx=0
   fy=0
  end
 end

 --checkpoint collision
 x=flr8(px)*8
 y=flr8(py)*8
 if (pmsget(8)==47) checkpointnow(x,y-8)
 if (pmsget()==47) checkpointnow(x,y)

 --spike collision
 if pmsget(7)==30 or
    pmsget(7)==31 then
  if fy>0 then

  spiketexts={"sharp and pointy, very hurty",
              "spikes? ouch.",
              "ouch!",
              "oh dear"}

  rndmsg()
  addtext(spiketexts[spheremsg])

   dienow()
  end
 end

 --fire collision
 if not dead and not super then
  if (not cring and pmsget(8)==19)
  or pmsget()==19 then

  firetexts={"fire: it's hot",
             "well... better to burn out?",
             "dont touch the flames!",
             "oooh, burn!"}

   rndmsg()
   addtext(firetexts[spheremsg])

   dienow()
  end
 end

 --water collision
 if not dead and super then
  if (not cring and pmsget(8)==20)
  or pmsget()==20 then

  watertexts={"made of fire? avoid water!",
              "your flame is not eternal",
              "extinguished",
              "fire vs water? water wins."}

   rndmsg()
   addtext(watertexts[spheremsg])

   dienow()
  end
 end

end

function rndmsg()
 spheremsg+=1+flr(rnd()*2)
 if(spheremsg>4)spheremsg=1
end

--set checkpoint
function checkpointnow(x,y)
 if cx!=x or cy!=y then
  sfx(6)

  checktexts={"the sphere glows warmly",
              "it glows upon your touch",
              "you feel protected",
              "the sphere will remember you"}

   rndmsg()
   addtext(checktexts[spheremsg])

 end


 checkpointing=true

 checkwopen=wopen
 checkwlit=wlit
 checkeopen=eopen
 checkelit=elit
 checkinv=inv

 cx=x
 cy=y

 addpart(1,x+rnd()*7,y+rnd()*7,-1,0,3-cpu)--+rnd()*2)

end

--death becomes her!
function dienow(k)
 killer=k

 fadeout=16
 sfx(0)
 fx=0
 fy=0
 kx=px
 ky=py
 dead=true
end

function respawnnow()
 px=cx+4
 py=cy+8
 --pg=0
 dead=false
 respawning=true

 wopen=checkwopen
 wlit=checkwlit
 eopen=checkeopen
 elit=checkelit
 inv=checkinv
end

--like mget, but you can
--enter screen/pixel xy
function msget(x,y)
 return mget(flr8(x),flr8(y))
end

--used msget so much just for player might as well
function pmsget(b)
 if (b)return msget(px,py-b)
 return msget(px,py)
end

--can we stand?
function canstand()
 if(collides(px,py-8))return false
 return true
end

--does xy overlap a map tile
function collides(x,y)
 if(x<1) return true--left edge of map
 if (mget(flr8(x),flr8(y))>=64) then
  return true
 else
  ycol=8
  if (cring) ycol=7
  if (mget(flr8(x),flr8(y-ycol))>=64) return true

  return false

 end
end

--order to fade pixels
whitefade={1,2,3,5,13,13,15,7,
            9,10,7,10,6,6,15,7,7}
blackfade={0,0,1,5,5,2,15,6,4,
            4,9,3,13,5,13,14}
function fadepix(col,lookup)
 return lookup[col+1]
end

--actor-actor collision
function actoraabb(a,b)
 if a.x+7>b.x and
    a.x<b.x+7 and
    a.y+7>b.y and
    a.y<b.y+7 then
  return true
 end
 return false
end

--point-box collision
function pbox(x,y,bx,by,w,h)
 if bx>x or
     bx+w<x or
     by>y or
     by+h<y then
  return false
 end

 return true
end

--point-circle collision
function pcirc(x,y,rad,ax,ay)
 if(pbox(x,y,ax-rad,ay-rad,rad*2,rad*2)==false) return false
 distx=ax-x
 disty=ay-y
 distx*=distx
 disty*=disty
 if (distx+disty>rad*rad)return false
 return true
end

--adds message text to the first
--empty slot in the buffer
function addtext(text,delay)
 for i=1,count(texts) do
  if texts[i]=="" then
   texts[i]=text
   texttimes[i]=15
   if (delay) texttimes[i]=delay
   return
  end
 end
end

--remove first text in buffer
--shuffles everything forward
function removetext()
 textscount=count(texts)
 for i=1,textscount-1 do
  texts[i]=texts[i+1]
  texttimes[i]=texttimes[i+1]
 end
 texts[textscount]=""
 texttimes[textscount]=0
end

--display game events as
--scrolling text on the bottom
function displayevents()
 if(gametitle)return

 rectfill(16,112,127,127,0)
 clip(16,112,127,35)

 if textscroll>0 then
  textscroll-=1
 else
  if(texttimes[1]>=0) texttimes[1]-=1
  if texttimes[1]<0 and texts[4]!="" then
   textscroll=7
   removetext()
  end
 end

 texty=121
 textcols={13,6,7}
 --textcol=7
 for i=3,1,-1 do
  print(texts[i],16,texty+textscroll,textcols[i])
  texty-=7
 end

 clip()
end



function drawstatue(x,y,f,l)
 if l then
  if rnd()>0.7 then
   pal(6,15)
   pal(15,10)
   pal(10,7)
  end
 else
  pal(6,6)
  pal(15,6)
  pal(10,6)
 end
 sx=16 sxx=24
 if(f)sx=0 sxx=0
 spr(89,x,y-24,4,3,f)
 spr(93,x+8,y-48,2,3,f)
 spr(103,x+sx,y-64,2,2,f)
 spr(95,x+sxx,y-48,1,1,f)
 pal()
end

function wrap(v,max)
 while v>max do v-=max end
 return v
end

function fadecirc(cx,cy,rad,lookup,strength)
 cx=flr(cx)
 cy=flr(cy)


 cxb=cx-rad
 cyb=cy-rad
 cyc=cyb
 yy=rad*2
 xx=rad*2
 fill=false
 clip(0,0,128,112)
 for x=cx-rad,cx do
 for y=cy-rad,cy do
  if fill or pcirc(x,y,rad,cx,cy) then
   fill=true

   pix=pget(cxb,cyb)
   for i=0,strength do
    pix=fadepix(pix,lookup)
   end
   pset(x,y,pix)

   if xx>0 then
   pix=pget(cxb+xx,cyb)
   for i=0,strength do
    pix=fadepix(pix,lookup)
   end
   pset(x+xx,y,pix)
   end

   if yy>0 then
   pix=pget(cxb,cyb+yy)
   for i=0,strength do
    pix=fadepix(pix,lookup)
   end
   pset(x,y+yy,pix)
   end

   if xx>0 and yy>0 then
   pix=pget(cxb+xx,cyb+yy)
   for i=0,strength do
    pix=fadepix(pix,lookup)
   end
   pset(x+xx,y+yy,pix)
   end

  end
  cyb+=1
  yy-=2
 end
 yy=rad*2
 fill=false
 cyb=cyc
 cxb+=1
 xx-=2
 end

 clip()
end

function _draw()

 --fadeout stuff
 camera()
 if fadeout>=0 then
  if(gametitle)rectfill(0,127,127,112,0)
  kx=wrap(kx,128)
  ky=wrap(ky,111)

  --draw whatever killed us
  if killer then
   --eyedol
   kkx=killer.x
   kky=killer.y
   ppx=px
   ppy=py-9
   if(cring)ppy=py-4
   kkx=wrap(kkx,128)
   kky=wrap(kky,111)
   ppx=wrap(ppx,128)
   ppy=wrap(ppy,111)
   spr(26,kkx-4,kky-4)
   line(kkx,kky,ppx,ppy,11)
   killer=false
  end

  fadeout-=1
  fadey=111
  fade=blackfade
  if gameover then
   fade=whitefade
   fadey=127
  end
  if(fadeout==0)gametitle=false
  for x=0,127 do
   for y=0,fadey do

    pix=pget(x,y)

    if fadeout<8 or gametitle or gameover then
     pix=fadepix(pix,fade)
    else
     if pcirc(x,y,20,kx,ky-10)==false then
      pix=fadepix(pix,fade)
     end
    end
    if(pix>=0) pset(x,y,pix)
   end
  end
  if (not gameover) displayevents()
  return
 end

 if gameover then

  print('"fear not child',35,54,0)
  print('your home awaits"',32,62,0)
  print("the end",49,100,6)

  return
 end

 cls()
 rectfill(0,0,127,111,1)


 woff=flr(px/128)--world offset
 yoff=flr(py/112)

 --draw stars using world offset as seed
 srand(73+(woff-3)*(yoff+58))
 for i=0,20 do
  if sin(time*rnd(1))>0 then
   pset(rnd(127),rnd(112),7)
  else
   pset(rnd(127),rnd(112),15)
  end
 end
 srand(time)

 if gametitle then
  --print("dusk child",68,19,7)
 -- print("by sophie houlden",54,38,6)

  print("by sophie houlden",54,37,13)

  if sin(time*2)>0 then
   print("press button",64,72,7)
  end

  woff=0 yoff=1
  map(0,14,0,0,16,14)
  drawstatue(8,72,false,true)
  camera(0,112)

  goupdate()
  doparticles()
  return

 else
  --draw stuff below game
  invspr=0
  if inv!=0 then
   invspr=actors[inv].b
   --if actors[inv].t==4 then
   -- invspr=2
   -- bucketpal(actors[inv].b)
   --end
  end

  spr(invspr,4,116)
  pal()
  line(3,114,12,114,6)
  line(2,115,2,124,6)
  line(3,125,12,125,6)
  line(13,115,13,124,6)

  displayevents()
 end


 camera(woff*128,yoff*112)

 --draw map
 map(woff*16,yoff*14,woff*128,yoff*112,16,14)




 --draw actors
  godraw()

 --draw checkpoint
 spr(46,cx,cy)

 --particles
 doparticles()

 --player animation
 curani={}--current animation
 if pg==0 then
  curani=fall
  if (fy<0) curani=rise
 else
  if btn(0) or btn(1) then
   curani=walk
   if (cring) curani=crawl
  else
   curani=idle
   if (cring) curani=duck
  end
 end

 if (cutscene) curani=idle

 lastframe=aniframe
 anitime+=0.5
 if (anitime>1) anitime=0 aniframe+=1
 if aniframe>count(curani) then
  aniframe=1
 end
 animsprite=curani[aniframe]

 --walk sfx
 if aniframe==1 and lastframe!=aniframe then
  if (curani==walk) sfx(2)
  if (curani==crawl) sfx(3)
 end




 --draw player
 if super then
  --flame pallete swap

  orange=9
  yellow=10
  if rnd()>0.4 then
   orange=9
   yellow=15
  end

  pal(1,yellow)
  pal(2,yellow)
  pal(3,orange)
  pal(4,7)
  pal(5,7)
  pal(6,orange)
  pal(7,yellow)
  pal(8,orange)
  pal(11,7)
  pal(13,7)
  pal(12,orange)
  pal(14,yellow)
  pal(15,yellow)
  pal(9,orange)



  for i=0,5 do
   sparkcol=7
   if (rnd()>0.5) sparkcol=9
   if (rnd()>0.5) sparkcol=10
    addpart(1,px+(rnd()*4)-2,py-(rnd()*16),sparkcol,0)
  end

 else
  --normal pallete swap
  pal(1,3)
  pal(2,4)
  pal(7,5)
  pal(9,4)
  pal(10,11)
  pal(12,5)
  pal(14,8)
  pal(15,13)
 end

 spr(animsprite,px-4,py-15,1,1,pf)
 spr(animsprite+16,px-4,py-7,1,1,pf)
 pal()

 cpu=stat(1)
 --print(cpu,woff*128,yoff*112,7)
 --print(wopen,woff*128,yoff*112+20,7)
 --print(eopen,woff*128,yoff*112+40,7)
end
__gfx__
005005000077760000666600006666000066660000666600000000000555555005555050000000006600006d6600006d6006006003003000000000000000fff0
0500500507bbb3b006cccc6006555d6006555d6006555d60000006000505505005505050007777005d6666d55d6666d50660606600330f3000000000000ff666
500500507b7bbb3306cccc6006cccc600655d5600655d5600000560000050050050050000b3b337006dddd5006dddd5006066660030f353000000000000f5f65
005005007bbbb3b506cccc6006cccc6006cccc6006155d60000565000005000005005000b6b7bb63065dd55006ddd550060060603f353053000000000006ddd5
050050057bbbbb350d6666500d6666500d6666500d6666500066550000000000050000000b3b363006bd5b50065d5550060006060333053000000000000d6d50
5005005063b3b3350dd5d5100dd5d5100dd5d5100dd5d510006d5500000000000000000000b6630006d5555006d555500d0000600f30f3330000000000f055d6
005005000b3b335000dd550000dd550000dd550000dd5500006dd5000000000000000000000b300000d6d50000d6d5000000006033f3035303003003f00fdf65
050050050035550000d5d10000d5d10000d5d10000d5d100006dd500000000000000000000000000006555000065550000000006003055300330303006065655
00088000000880000000000090909090c0c0c0c0000880000000000000eee00000000000000d50456600006d6600006d55225222034043000000000000000000
008e2900008e290000088000090909090c0c0c0c008e2900900880900e000e0000000000006666005d6666d55d6666d505532222000445000000000000000000
0082420000824200008e290090909090c0c0c0c000824200308e29300e000e0000000000066ddd5006dddd5006dddd5000555225000450008000800000008000
000442000004420000824200090909090c0c0c0c00044200308242100e000e000000000006d66d5006adda500aaddaa000052522004450006000800080008080
00020000000200000004420090909090c0c0c0c009020009100442100e000e000000000006d65d500abaaba00abaaba000005552000450006080608060008060
001110000011100000120000090909090c0c0c0c31111030013201000e000e000000000006ddd55006a55a5006aaaa5000000052000450006060606060806060
011ba100011ba1000131100090909090c0c0c0c0011ba100011110000e000e00000000000055550000d6d50000d5650000000055000455006333333033606033
011bb100103bb109101ab109090909090c0c0c0c001ba0000011a00000eee0000000000000040000006555000065550000000005004455003222222322333322
011bb100033bb3300311b1300000088000008800001ba000001ba000006666666666660000050000006dd5000666d6d0222322550000000000aaaa0000777700
03fdd300009dd000009dd00000008ee80008ee80001dd000001dd00006dddddddddddd5000040000006dd5006dddddd522222550000000000a9998a007000c70
09fff90000ffd00000fdf00000118e490018e49000fd770000ff570006d555d5d55d5d5000050000006dd500055555502252250000000000a9a99984707000c5
0050500000df5500000f5000031ba994011a994000f507000005007006dddddddddddd5000040000006dd50000d5d5002222500000000000a999989470000c05
00707000005007000005070003bbbbb103bbbb1100700c0000070c0006d55d5555d55d5000050000006dd50000dd55002525500000000000a99989847000c0c5
070070000c000c00006cc000053d7b110f3d57730c000c6000c0066006dddddddddddd5000040000006dd500006dd5002225000000000300a89898847c0c0cc5
0c00c00060000c60006600000fc9fcc3c7539fc9600006000060000006d5ddd55dd55d5000050000006dd500006d550025500000003303000a89884407c0cc50
0660660006000600000660000660660966000660600000000006000006dddd5dd5dddd5000040000006dd500006dd50055000000030303306d4444d56d5555d5
00dddd5555dddd00000990000070007000000000000000000000000006d55d5dd5dd5d50066d6600006dd500006dd50005d66660666d50000aaafaf005ddd550
0d66d500005d66d0000990000c0070cc00999900000000000000000006dddd5dd5dddd50600400d0006dd500006dd50005ddd66066dd5000a999999400051000
d6dd50000006dd5d009aa9000007c00c09aaaa90000000000000000006d5ddd55ddd5d50600000d0006dd500006dd50005dd6d606d6d5000f494949400065000
d6d5000000006d5d009aa9000007cc0009a77a90000000000000000006dddddddddddd50600000d0006dd500006d550005dd6d606d6d5000a4494994000d1000
d6dd50000006dd5d09aaaa90c0ccc10009aaaa90000000000000000006d5d55d5d555d50600000d00666d5500055650005dd6d606d6d5000f999999400065000
d6ddd500006ddd5d09a77a9000cc1c00009aa900000000000000000006dddddddddddd50600000d000d555000006d50005dd6d606d6d500004444440000d1000
0d555d6006d555d009aaaa90000cc000009aa90006d500d0000006d006d555d5d5555d50600000d00666d550006dd50005ddd66066dd50000005500006666650
00ddddd66ddddd000099990000000000000990006d5506550d506d5505555555555555504949494066dd5d55006dd500055ddd606dd55000006d55006dddd511
d666666dd666666d0330033003330330033333300330033034444433d55555555555555d0666666666666666666666d052222ff2033003300333333003300330
6dddddd56dddddd5333333333355333335335553335533332545445255666666666666556ddddddddddddddd5555555522322d6f333333333533555333553333
6dddddd56dddddd5335555235222525352255225352555332245544256d66dddddd6dd5556d6d6d6d6d6d6565d5d5d552222f65d335555235225522535255533
6dddddd56dddddd535525225222322225322222252222553245225425665566dd6656555055ddddddddd555555555550222f6522355252255222222252222553
6dddddd56dddddd535225222222522222222222222225250224222455665d556655d65550055555ddd555555555555002ff6d222352222222222222222225250
6dddddd555ddddd5052222222322222222222222222222502242245456d65dd55dd65d550000555555555555d55500002fdf6222052522522522525222222250
6dddddd52555ddd5052222222222225222222322222522502222242256d65dd66dd65d550000006ddddddddd55000000222d5252052552555552555552552250
d555555552555555552225222222222222222222222222252222224256dd656dd565dd55000006d5555555555550000023222222005005550055555055055500
6666666d666d006d52222252225222225222522222222225d600500d56dd656dd565dd550000000055dddddd555dd6ffdfafafad0000000005ddddd6ffffff00
6dddddd56dd556d5522222222222232222222222252222556d50406556d65dd55dd65d550000000555ddddd6ddd555d6fdfdddd000000000056ddddffaaaa000
6ddd55d56dd56dd5522222222222222222222522222222506d50506556d65dd66dd65d55000000555ddddd6ff6dd5555d555550000000000055fdd6faaaa0000
6dddd6556d556dd5552222225222222222222222222222556d5040655665d665566d6555000000555dd6fdd6fffd5055d66d500000000000555ffffffaa00000
6ddddd606d56ddd5552522222222222252222222222322256d50506556d6655dd5566555000005555d6ff6ddd6dd550555550000000000055dddffffaaa00000
6dddddd66d56ddd5552223222222225222222522222225256d50406556d55dddddd55d5500000555ddfffd55ddd55d5000000000000005555ddf0faaaa000000
6dddddd5656dddd5522222222225222222222222222222256d505065555555555555555500000555dd6ffff65555dd65000000000000555d5dddd00000000000
d5555555d555555505222222222222222325222222522250d500400dd55555555555555d00000555dddfffff6655dd6f0000000000005dddd6fdf00000000000
09e9e696969696e00522222225222252222222222222225000066d00000000000000000000000555ddd6fffffa655dd6f000000000055d6ddd666500666dd66d
9e9009f9f204f9fe552225222222222222222252222525550006d5000000000000000000000005555dddd6fffffa55dd6f0000000005ddd66ddddd006dd56dd5
e900000fa000af9f552222222222222222222222222222550006d5000000000000050000000000555ddddddfffffaf5dd6f000000005dddfdddddd606dd56dd5
9e0000000a0afaf952222222322252222225222222222225000d550000000050000050000000000555dddddd6ffffaf5dd66000000055ddfddd6d5d06dd56dd5
e909ff22a000afaf5222252222222225222222225232222500066d0000050005000055000000d6f55555dddddd6fffaf5ddf000000055ddaddd66d506ddd56d5
9e9ffafaf100aaf9552222222222222222222222222222250006d50000500005500555000005ddd6f55555ddddddfffff5ddf00000055d6addd666d06ddd56d5
e9f9ff0000000faf522522222522225222232222222252250006d50000500005505550000005dddddd6f65555ddddfffff5d600000055dffddd6dfd06ddd56d5
9e044200a0002aff05222522222222222222222252222250000d550000550055d555d0000005d55ddddddd6ff55dddffff65d60000055df6dddf6ffdd555dd55
e900000f0000afa9052222222222225222222522222222500000000005550055d55d500000055555dddddddddd6fddd6f6665d0000055dfddd6ff6ffd66d666d
9e0000faf0a0faff552222255225225222222222222225500000000005550555d55dd50000005555555ddddddddd6dddd66d5dd00055dd65ddffad6a6dd6ddd5
e99f9fafa0f0aff9522232222222222225222225225222550000000000555555dd5ddd00000055555555555ddddddddddddd5dd00055ddff5dfa6da06dd5ddd5
9ef9fffa0fa0ff9f5252222222222222222222222222232500000000005d5555dddddd0000005555500d555555dddddddddd5dd00055dd6ffd66d6d06dd55dd5
e9ef9fff01f019fe05222222222222322222222222222255000000000055d55ddddddd00000055550005dd5555555ddddd555d5000555dd6ff5d6fd06d5005d5
9e9e42000000012905255252522252225222225252222225000000000055d55dd6666d000000555d000555d05555555555555550000555dddfa566d0d5000055
e94000000000000252552555525225255552525555252555000000000555dddd66fff600000055dd60055550000555555555550000555555dd6f5d600000000d
090000000000002005555550055555500555555000555550000000000555dddd6fffff000000055ddd0055dd0000055550555000055ddd5555ddfa5d00000000
04000000161600000000000000000025040504f6040404354546364636464504355400000000000000000000000000000000000000000000000000a2000000e0
d2161600000000000000000000161600e000d1d2000000000000000000253646044654e0000000000000000486f6860404e104800000000000000000f104c0f6
040000001616000000000000000000140404040404f60404143747373736ce45cf3754000000000000000000000000000000000000000000000000a200d43444
5416160094a4b4000094a4b40016162444446434e4f400000000000000c137473747354454d2000000000004040415040404000000000000005300e105700004
050000161616c500000000000000000514f704f70404f704f705800070c13646567656000000000000000000000000000000000000000000000000a20000c146
461616c553b263000000b253b5161614cf4546563300000000000000000070808000c13747f400000000636500000000800000000000000004f6000480000005
0400001616161600000000000000000404760476040476047604000000002747470457000000000000000000000000000000000000000000000000a300d20025
462e16040e2f1f1f1f1f2ff604162e46bf46365741000000000000000000000000000031310000000004f6650000000000000000000000000000000000000004
f60063161616160000000000000000040404f704040415040404000000007000800000000000000000000000d000000000000000000500000000d4e444443446
352e2e1600c307000000d300162e2e461447c28041000000000000f20000000000000031310000000000000000000000f2000000000063000000000000000004
0400040404f6040400000000000000f604b2000000000000b265000000000000000000000000f200d2e05300d10000000000000000b2000000000000c1f60404
1404f70400c300000000d300f6041504047000004100000000d200f300d2e00000e0d22323d2000063e300e700005300f3630000000e05000000000000e1e1f6
0400b200630000b2000000000000000000a2000000000000a265000000000000000000000000f3d2244444346454e000d200000000a200000000000000b20000
8000000000c300000000d30000273645f60000004100000000d4e4e4e4443444344434443444041504041504f604050404f7000000008000000000000004f7f6
0404040405000015040000000000000000a2000000000000a20000000000000000000000d224344445cf35bf354544443444e454e0a300d20000000000b30000
0000000000c371717171d3000000c13757000000410000000000000070c1be464536364645ce8404057484040474840404000000000000000000630000800004
5663b200000053b2005300000000630000a3536300006300a3d700e30000d20000e024344436ce46cf463545cfcf3545cf5576264434344454000000d2a30000
e000e363244444344434445400d200e000d2000041e000000000000000e0263545354514ce75850404758504f6758515f6000000000000000000150000000004
35f6045400001404040504041544140404f6040415050404041404041534444434443636cf35453636c43646364636be36460436463545bf4634444434443444
4414f60404354545cf36361434443434344434344434444434540000244436364636460414150e04f60404040404040404e1e1000000000000e105e100000005
04be14150000f60404044714043747f7041447040447f73747f604143545be041404040404f604040404040404040415363646144704f6474714040504040404
040504354704040415044704374704141436473746363565465600002504040404040404c4140404360404363614040e0404f70000000000001504f600e16304
14353556e0000000000070000000000000007000000000008000c13536cf45040474840500000000000000c004748404053647c2000000007000000000f6f704
140404c270000000000000008000c00536c270912737476537570024363535453537474735041435c20000c13747350405800000000000000000000000f60404
463535475400d200000000000000000000000000d200000000000025cf3635f60475850400000000000000000575850436c280000000000000000000f2000000
00000000000000000000000000000004c200009200008000000000273747374757800080c13635560000000070c0260404000000000000f1f1000000000080f6
46bf5670c1e4344454e000000000d224344434443454e0000000002646cf46bf040404550000000000000000043604f6f60000000000000000000000f3005300
00000000000000000000000000000000000000920000006600e0d20070d20000e0000000000435c2000000000000c114f60000000000f11404000000e1000005
0435c2000000c13747e4e4f400002404054545354546540000000025cf3535040405360454000072820000241404040404000000000015040400040415040404
150400000000000000000000000000000000009224443444344434443444343444540000000556000010530000000004f60000f1000004f6e1f1000004f70004
14c20000000000b2700000000000c104043645cf46355500000000253545350404451404560000731700002604450404560000000000c004040004041404f604
0504530000000000000000000000000000d2309326353545354535453645353636550000e004c25315040463e30000040500f105000000c004040000000000f6
56000000000000a300e1f1e1f1e1f1141445cf35ce365600000000264635ce05040404f6355400f5e5002435350414040404000000000004f6000404bf140404
04f6f70000000405000004f70000f644443444343536143546353646353635be45c20000d404f704040404040405001404000414e1f100000000000000630004
5600000000e02444343635363536be0435ce373745463554000000c13545351404748404355500000000263504748404f60000000000530404000404f7040504
14f1e1f1e1f1e1e1f1e1f1f1f1e1e115cf36454645be4645464547374545bf365500000000b200910000040000b20004f6000404f704000000e1f1e100041504
04000000002445454537473747374714f6c27080c13735550000000025353635047585044556000000002645147585f60400000000000404050091000000c004
f74704f7f60404040404f70404151447374747454605464647c23300c14747365600000000a200920000650000a3630414008092000000000004040500040404
56000000002537475770800000800000000000000000275700000000263635f704f7040404040500001504040404f60404000000000000650000920000000000
00000000000000000000000000000000007000c1374747578000410000b200c147f4000000b300920000650000040404560000920000f1e1f1e1f1e1f1650404
04e00000d457337000000000d200e0000000000000003131000000002747c200b20000b20000b20000b20000b20000f704150400a00000650000920000000000
000000000000a000000000000000000000000000b20070000000410000b300008000000000a20000000000000004f6045500009200041404040404f704650404
04540000000041000000d22434344404040000000000313100000000f2700000b30000a20000a20000a20000b300636004000000b20000000000000000000000
000000000000b20000000000000000000000f200a20000000000410000a200000000000000a300935300666300040404040000000000f20000000000000000f6
ce455463e00041d2243444454545454504530000e000232363000000f3000000a30000a30000a30000a30063a35305f614546300a30000660063930000000053
000000006300a30000000020000063d2e000f300a300e000d20041e000a300d2d20000e0630404040404150404040404566320930063f30000e00053e3661004
043504f644441534450404350404ce0404044414340415f604441444340404040444040404040404040404040404040446461405040404043404043444041504
043405040404043444f644041405344434443444343434443434444434443434444434441404f60404040404040404f604f60404441404f64444140404040404
d666666d00dd666d222222220555500500050055500500000000000000005550050005055505000055550000225222222ddd2225000000000000000000000000
6dddddd50006ddd5222222225dddd55d505d55ddd55d5000000000000005ddd55d505d5ddd5d5005dddd50002222dd52dddddd22000000000000000000000000
6ddddd550005ddd5222222225d666d5d505d5d666d5d500500000000005d666d5d505d56d65d5005d666d500222dddd5ddddd5d2000000000000000000000000
6dddd55d00006dd5222222225d555d5d505d5d55565d505d50000000005d55565d505d55d55d5005d555d50052ddddd55d555ddd000000000000000000000000
6ddd556500006dd5222222225d505d5d505d5d50055d55d650000000005d50055d505d55d55d5005d505d50022dddd552552ddd5000000000000000000000000
6dddd6d50006ddd5222222225d505d5d505d5d55505d5d6500000000005d50005d555d55d55d5005d505d500225d5555222ddd55000000000000000000000000
6dddddd506ddddd5222222225d505d5d505d56ddd55dd65000000000005d50005ddddd55d55d5005d505d50022255552225dd552000000000000000000000000
d555555d0d555555222222225d505d5d505d55666d5d6d5000000000005d50005d666d55d55d5005d505d5002222552232255522000000000000000000000000
d6666660d666666d006dd5005d505d5d505d50555d5d56d500000000005d50005d555d55d55d5005d505d5002222ddd222222222000000000000000000000000
6ddddd506dddddd506dd55505d505d5d505d50005d5d556d50000000005d50005d505d55d55d5005d505d5002225dd5522222222000000000000000000000000
6ddddd55d5555555555555555d505d5d505d55005d5d505d50000000005d50055d505d55d55d5005d505d5002225555222222222000000000000000000000000
6dddddd55dddddd55dddddd55d555d5d555d5d555d5d505d50000000005d555d5d505d55d55d5555d555d5002dd2252222222222000000000000000000000000
6ddddd6ddd6666dddd6666dd5dddd656ddd656ddd65d505d500000000056ddd65d505d5ddd5dddd5dddd6500dddd222222222222000000000000000000000000
6ddddd6dd6dddd6dd6dddd6d56666505666505666556505650000000000566655650565666566665666650005ddd522222222522000000000000000000000000
d55d66d66666666666666666055550005550005550050005000000000000555005000505550555505555000025d5522222222222000000000000000000000000
0055dd60555555555555555500000000000000000000000000000000000000000000000000000000000000002255222222222222000000000000000000000000
__label__
22222222d666666d5222522222222252222225222223225511111111111111111111111111111111111111111111111111111111111111111111111111111111
222222526dddddd52222222252252252222222222222255111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222226dddddd52222252222222222252222252252251111111111111111111111111111111111111111111111111111111111111111111111111111111111
222522226dddddd52222222222222222222222222222511111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222226dddddd55222222222222232222222222525511111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222226dddddd52222252252225222522222522225111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222322226dddddd52222222252522525555252552551111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222d55555552325222215555551155555515511111111111111111111111111111111111111111111111111111111111111111111111111111111111111
666dd66d252222522222222511111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dd56dd5222222222522225511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dd56dd5222222222222225111111111111511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dd56dd5322252222222225511111151111151111111111111111111111111111111111111111111111111111111111111111111111111111111111111171111
6ddd56d5222222252223222511151115111155111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6ddd56d522222222222225251151111551155511111111111111111111111111111111111111111f111111111111111111111111111111111111111111111111
6ddd56d5252222522222222511511115515551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
d555dd55222222222252225111551155d555d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
d666666d222222222222225115551155d55d511111111f1111111111155551151115115551151111111111111111555115111515551511115555111111111111
6dddddd5222222522222255115551555d55dd51111111111111111115dddd55d515d55ddd55d5111111111111115ddd55d515d5ddd5d5115dddd511111111111
6dddddd5222222222252225511555555dd5ddd1111111111111111115d666d5d515d5d666d5d511511111111115d666d5d515d56d65d5115d666d51111111111
6dddddd52225222222222325115d5555dddddd1111111111111111115d555d5d515d5d55565d515d51111111115d55565d515d55d55d5115d555d51111111111
6dddddd522222222222222551155d55ddddddd1111111111111111115d515d5d515d5d51155d55d651111111115d51155d515d55d55d5115d515d51111111111
55ddddd522222222522222251155d55dd6666d1111111111111111115d515d5d515d5d55515d5d6511111111115d51115d555d55d55d5115d515d51111111111
2555ddd522232222552525551555dddd66fff61111111111111111115d515d5d515d56ddd55dd65111111111115d51115ddddd55d55d5115d515d51111111111
5255555522222222115555511555dddd6fffff1111111111111111115d515d5d515d55666d5d6d5111111111115d51115d666d55d55d5115d515d51111111111
22222222222222511111111115ddddd6ffffff1111111111111111115d515d5d515d51555d5d56d511111111115d51115d555d55d55d5115d515d51111111111
222222522225255511111111156ddddffaaaa11111111111111111115d515d5d515d51115d5d556d51111111115d51115d515d55d55d5115d515d51111111111
222222222222225511111111155fdd6faa5a111111111111111111115d515d5d515d55115d5d515d51111111115d51155d515d55d55d5115d515d51111111111
222522222222222511111111555ffffffaa1111111111111111111115d555d5d555d5d555d5d515d51111111115d555d5d515d55d55d5555d555d51111111111
2222222252322225111111155dddffff5aa1111111111111111111115dddd656ddd656ddd65d515d511111111156ddd65d515d5ddd5dddd5dddd651111111111
2222222222222225111115555ddf1faa5a1111111111111111111111566665156665156665565156511111111115666556515656665666656666511111111111
22232222222252251111555d5dddd11111111111111111111111111115555111555111555115111511111111f111555115111515551555515555111111111111
222222225222225111115dddd6fdf111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222222223225511155d6ddd666511151111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222252222225511115ddd66ddddd111111111111111111111111111111111111111111111111f1111111111111111111111111111111111111111111111111
22222222225225111115dddfdddddd61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222522222222511111155ddfddd6d5d1111111151111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222222525511111155ddaddd66d51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222222225111111155d6addd666d11111115111111111111111ddd1d1d111111dd11dd1ddd1d1d1ddd1ddd11111d1d11dd1d1d1d111dd11ddd1dd11111111
222322222551111111155dffddd6dfd1111151a111111111111111d1d1d1d11111d111d1d1d1d1d1d11d11d1111111d1d1d1d1d1d1d111d1d1d111d1d1111111
222222225511111111155df6dddf6ffd1111511111111111111111dd11ddd11111ddd1d1d1ddd1ddd11d11dd111111ddd1d1d1d1d1d111d1d1dd11d1d1111111
222222511111111111155dfddd6ff6ff1111915111111111111111d1d111d1111111d1d1d1d111d1d11d11d1111111d1d1d1d1d1d1d111d1d1d111d1d1111111
22252555111111111155dd65ddffad6a111a115111111111111111ddd1ddd11111dd11dd11d111d1d1ddd1ddd11111d1d1dd111dd1ddd1ddd1ddd1d1d1111111
22222255111111111155ddff5dfa6da1111115111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222225111111111155dd6ffd66d6d111a511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
523222251111111111555dd6ff5d6fd111a5a5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222222511111111111555dddfa566d1191519511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222252251111111111555555dd6f5d611a755aa11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
5222225111111111155ddd5555ddfa5d11775a111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222251111111155dddddd555dd6ffdfafafad1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
252222551111111555ddddd6ddd555d6fdfdddd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222251111111555ddddd6ff6dd5555d55555111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222255111111555dd6fdd6fffd5155d66d51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22232225111115555d6ff6ddd6dd5515555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222252511111555ddfffd55ddd55d51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222222511111555dd6ffff65555dd65111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111f11111
2252225111111555dddfffff6655dd6f111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222222511111555ddd6fffffa655dd6f11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
25222255111115555dddd6fffffa55dd6f1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222251111111555ddddddfffffaf5dd6f111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222551111111555dddddd6ffffaf5dd6611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222322251111d6f55555dddddd6fffaf5ddf11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222225251115ddd6f55555ddddddfffff5ddf1111111111111111111111111111111111111111111111111111111111111111111111f11111111111111111111
222222251115dddddd6f65555ddddfffff5d61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
225222511115d55ddddddd6ff55dddffff65d6111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222225111155555dddddddddd6fddd6f6665d111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2225255511115555555ddddddddd6dddd66d5dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222255111155555555555ddddddddddddd5dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222222511115555511d555555dddddddddd5dd11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
52322225111155551115dd5555555ddddd555d511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222251111555d111555d155555555555555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22225225111155dd6115555111155555555555111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
522222511111155ddd1155dd11111555515551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
52225222d666666d666d116dd66d666d6666666d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222226dddddd56dd556d56dd6ddd56dddddd51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222225226dddddd56dd56dd56dd5ddd56ddd55d51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222226dddddd56d556dd56dd55dd56dddd6551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
522222226dddddd56d56ddd56d5115d56ddddd611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222252255ddddd56d56ddd5d51111556dddddd61111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222222555ddd5656dddd51111111d6dddddd51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2325222252555555d555555511111111d55555551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
225222222522225222232255111111111666d6d11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222223222222222222222551111111116dddddd51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222222222222252251111111111155555511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
5222222232225222222251111111111111d5d5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
2222222222222225252551111111111111dd55111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222252222222222225111111111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22252222252222522551111111111111116d55111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222222222225511111111111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222222222511111111111111111116dd5111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111
22222252222525551111111111111111116dd511111111111111111111111111111111111111111111111111111111111111111111111111111111f111111111
22222222222222551111111111111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22252222222222251111111111111111116d55111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222523222251111111111111111115565111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
222222222222222511111311111111111116d5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22232222222252251133131111111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
22222222522222511313133111111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
d666666d222222221331133111111111116dd51111111111111111111111111111111111111111f1111111111111111111111111111111111111111111111111
6dddddd5222222523355333311111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711
6dddddd5222222223525553311111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dddddd5222522225222255311111111116dd5111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dddddd52222222222225251111111111666d5511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dddddd522222222222222511111111111d555111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dddddd52223222222252251131131131666d5511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
d555555522222222222222251331313166dd5d551111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
666d116dd666666d2222222213331331133333311331133111111111111111111111111111111111111111111111111111111111111111111111111111111111
6dd556d56dddddd52222225233553333353355533355333311111111111111111111111111111111111111111111111111111111111111111111111111111111
6dd56dd56dddddd52222222252225253522552253525553311111111111111111111111111111111111111111111111111111111111111111111111111111111
6d556dd56dddddd5222522222223222253222222522225531111111111f111111111111111111111111111111111111111111111111111111111111111111111
6d56ddd56dddddd52222222222252222222222222222525111111111111111111111111111111111111111111111111111111111111111111111111111111111
6d56ddd555ddddd52222222223222222222222222222225111111111111111111111111111111111111111111111111111111111111111111111111111111111
656dddd52555ddd52223222222222252222223222225225111111111111111111111111111111111111111111111111111111111111111111111111111111111
d5555555525555552222222222222222222222222222222511111111111111111111111111111111111111111111111111111111111111111111111111111111
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

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
55002900001c745354535454535453546453ec636354737374747374646363636463737464fc645354636454ec536364eb54ec5354545354737473746353fb6440644074407f744040416f4074405340406f4053ec407441407f4041404140404140404140407f404040406f40405040414040504040406f406f404041407f40
650029000000325253fcebfc5353545363636454742c0008000700081c737474737500081c645363fc536364646363646364fc636473742c083b07081c41744140412c003a00002b2b00003a0000404c405354742c000800000000000000006f6f00000000000000002f0000000000000700000000000000000000616161616f
6500290000002b526353fc5363634c6353fc642c00000000000000000000000007000000006263646354fc54535453fc5354645455060700002a494a4b2b0c6f405500003300002a3b0000330000415353542c080000000000000000360000350000350000363500003f00000000350000003600000035003600000061616140
5500290000004d5354636463535453546364750000000000000000002d002d000e000000001c6f4040406f4063fc636463645354653a3600353a352b352a00626f6500001400003b2a00001400005264412c0000000000000000005140407f4040514040406f406f404051407f514040407f4040514040405000000061616140
650000000000001c636353546364fc64532c0000000000000000004d4e444344444500000000190c4040294164535454535463642c6f41514040407f6f3a0052644100001400003a3a0000140000626f650000000000000000000000000000404050474048404050000000000000000000000007000000000000000061616150
6500000000000000625363646363645455000d0000000000000000000062fc5364550000000029005250295253fc6454fceb545540000029000000000050355253550000140000343400001400004040500000000000000000000000000000406f40574058404000000000000000000000000000000000000000005b61616140
65000000000000005263fc64fc645464652d1d0e0000000000000000001c5364fc650000000029004040295163646453636464500000002900000000000040534165000014000013130000140000524140000000000000000a0000000000004141404040406f6f0000000000000000000000000000000a00000000616161616f
550000000000000052535453fbfc64545343464e4e4f000000000000000052ebfb6500000000290040405640411c54fc54642c56000000290000000000006f40402c000014000013130000140000624041000000000000002b00000000003540407f00000c40400000000000003500003500000000352b003600006161616140
650e2d00360e3e001c6364636463636463532c0700000000000000002d0e626464550000000029006f4056407f006263642c00560000002900000a000000404050000000140000131300001400001c7440000000000000002b000000000040505000000000006f000000000040407f5140516f00407f406f4000514040517f40
6344434444434500007274747374737374750000000000000000004d4344535474750000000029000000000000005263550000000000000000002b0000002b00002f000014000032130000140000000700000000000000003a0000000051502b2b00000000004000000000000000000000000000000000000000000007000040
53545353fc54652d0e002d000000000808002f0000000000000000001c64532c082b002d000e39003536660e000062fc650000662d0e0039002d3a3600003a36003f00001436002b3200001400003536353e0000000000002b0000000000003b3b00360300006f0000000000000a000000000000000000000000000000000040
63eb54535464634343444343450e002d00003f2d1e1f1e1f1e1f1e1f0f622c00003a0e42444344434441434445001c545500004d4e434444434441405140406f51413500404051406f407f4040406f404050002d0e0000363a0035000000363a3a0040405136500000404000002b000000000000000000000000000000000050
64fcfc54646453535464fc5464444343434443445363535363535463445500002d4244535453fc53547474742c00006265000000001c74645354eb5453414040535440002b00002a3b00002b000000414040514344434441404441406f6f404041406f404040403500405036003a00350000003600001e00001e00001e000040
535453fc54ebfb54fc545354fc54535463fc6354fc63546354ec64645465004244404041535474742c0000080000005265000000000007727374737474746440634150002a00002a2a00003b0000004040404040414040406f404040404040404040416f40414040514040406f4040405000004000005000004000006f000040
64405473742c00000000000000000000645354647473737473736464fc6500525363fc54632c0008000000000000001c2c000000000000000000000000001c53534150353a00003b2a00002a00000041514040407f7340746f404073746f4051405140407f41747374737473745453546f00005100004000006f000040000051
6f635500000000000000000000000000646364750000080007001c7474750062535354642c000000000000000000000000000000000000000000000000000062406f64414040003a2a00002a0000006f50000029000000073300000008001c64532c00002f00000700072b00081c63546f007f401e1f50000040000050000040
41647500000000e3e4e5e6e7e8e9ea00535465080000000000000e002d0e0062fb636475000000000000000000000000000000000000000000000000000000727f415140404051403a00363a3500006256000029000000001400000000000041650035003f00000000002a0000001c63410000407f404000006f000050000040
64650000000000f3f4f5f6f7f8f9fa0063642c000000000000424343444344645354550700000000000000000000000000000000000000000000000000000000000740406f404040407f404040500041560000290000000014000000000000726f00406f4040500000003a0000000062403500500000070000401f1e401e1f40
642c00000000000000000000000000006455000000000000005253eb6464535463646500000000000000000000000000000000000000000000000000000000002f0040400000004040000000404000070000000000000000140000000000000000002900000c56000040415000000052404000401e1f0000007f4040406f4040
65000000320000000000000000000000fb650000000000000e6263fc5354fc6464fc2c00000000000000000000000000000000000000000000000000000000003f35290000360040400000363529000066003539000000001400000000000000000029000000560000002b00000000625000006f414000000000000000000c40
55000000000000000000000000000000642c00000000004d4e546463636464646355000000000000000000000000000000000000000000000000000000000041407f56514050004040004040405640514051405000000000140000000000000000000000000000000000000000000e634000004033001e1f1f1e1e350000006f
550000000000000000000000000000005500000000000000071c6453fcec5464fc65000000000000000000000000000000000000000000000000000000000052400056003a3a006f40003a3a00560040407f6f0000000000400000000000353600353900023666000000000000004263400051401400406f407f404000000040
6500000000000000000000000000000065000000000e2d0000005263fc63fc535465000000000000000000000000000000000000000000000000000000000062400000006031004040001a310000004050000000000000000000000000517f40404041514040400000000000000052546f000000140000000000000000000040
5441517f50000000000000000000000055000000004245000000526364746463642c00000000000000000000000000000000000000000000000000000000426340007d360000004050003500007e004065001e0000000000000000000000004040532c00002b0000000000002d006263401e1f35141e1e00000000361e1f1e40
53632c002b0000000000000000000000550000004d737500000062642c081c645500000000000000000000000000000000000000000000000000000000001c534000406f40514040406f40404040006f651e4000001f000000000000001e1e62642c0000003b0000000006004d44fc5441406f404040500000003540406f7f40
64652d003b000000000000000000000065000000000000000000722c0000005265000000000000000000000000000000000000000000000000000000000000626f00403a4079404748407a403a5000405441401f1e500000001f00001e40534165000000002a000000003a36006263646f080000000000000000400000000040
4064450e3a000000000000000000000065000e1e1f1e1f1e1e1f1e1f00010e625500000000000000000000000000000000000000000000000000000000000e625000402b40004057585000402b400040fc644054536f1e1e1f401e1e40ecfc40650000002d3a0e0e00354243446453ec40000000000000000000000000000050
514164434445000000000000000000006443446464646464646464644343446465000000000000000000000000000000000000000000000000000000004244534000404050006f4040400040404000404040514063eb4040fc40405441406f40650000004d4344434443535341406364501e1f1f1e1f1e1e35361e35361f0040
404074416f4040407f4073744173404040414051535354546f40405354414040550000000000000000000000000000000000000000000000000000000000007241006f40307931406f307a314050004040507374407f73745340fc544140745465000000001c73634053546f535441404140406f4040404140406f4040500040
400007000061610000000008000700624053fc546363fc6453eb54636453535455000000000000000000000000000000000000000000000000003e00000000000000616100000000000000006161000000000007000008071c53ec6454550062550e00000000081c736353545354544041080000000000000007000000000040
50000000006161000000000000000040406f416453546364fcfb6463644c63645500000000000000000000000000000000000000000000000000404051000000000061610000000000000000616100000000000000000000001c7373646568405345000000000000071c63646364646f5000001e1e1f00000000000000000040
400000000061000000000000000000624040404051ec5354fcfc53fc53636441550e000000000000000000000000000000000000000000000000002b000000000000610000000000000000000061000000000d0000000000000000081c534454635500000000000000001c417f407f406f001f6f4050000000000000001e5141
__sfx__
000300002a07029070270702607024070220701f0701b0701907002070230702207021070200701e0701c07019070150700f0700b070020701b070240701807017070160701507014070120700f0700c07002070
000200001f07020070210702207025070270702807029070290702507027070280702a0702d0702f070310703207033070340703607037070370703107033070340703507037070390703b0703d0703f0703f070
000100000e610086200c620046200361003610016100000000000000000000000000000000000000000000000000000000000000000000000000000e60006600076000960009600096000a600046000000000000
000100000261002610036100361003610036100361003610036100261002610026100161001610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000080700d070150701b07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200000a0700c070090700607005070030700107000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000028070290701f0702a0701b0702b070160702c070110702d0700f0702e0700d0702e0700c070300700c070310700f0703107017070330701f0703407025070370702c070380703007039070340703a070
000100003507005070320701a0702f070090702c070170702707008070240701507020070270702f0703b070260700507032070100702c0700807028070180700907023070140702d070210702a070310703a070
00010000370700607035070160702f070080702c070170702907008070250701707020070280701e070350701f00000000280002300024000000000000000000000002000000000000001b000190001900000000
000200001a070050701e07016070220700507025070160702a0700c0702e0701f0702b650366503a6503e6503e6503e6503d65039650346502f65027650226501c6501865013650106500c650086500465001650
0002000028640376502565005040026100504012640106400f6400d6400c6400a6400864007640066400664006640056400464004640046400464004640036400364003640036400364003640086400b6400e640
000200000a6400a6400a6400a6400a6400a6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b6400b64017640296501c650016401f65030650246501e640
0002000010570131701557017170185701817017570161701457013170115700f1700d5700b1700a570091700857006170065700517005570041700457005170065700717008570091700b5700c170105700d170
000100000d620136301b64025640276402764026640246401d640176401464013640126401364016640176401764016640126400e6400a6400764004630036300263002620016200162001610016100161004600
000100000461004610046100462004620046200662008620096200b6300c6300e6301163014630176301a6301d63020630226301a6301a63018630186301a6301d63020630226302f63030630286301d63013630
001000001400014000170001b000210000500005000050000600009000090000b000090000a0000d000120001b0002500002000000001c0001d0001f00005000060000b0000f0001d00001000010000100002000
001000001d6000c6001d6000c6001d6000c6001a6000c6001b6000f600176000e600196000f600166000c600166000f600186000d6001a6000e6001b60006600206000e6001a6000f6001a600106001c6000e600
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 4f4e4344
02 4d4e4344
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
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
