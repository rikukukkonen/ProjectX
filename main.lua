local physics = require("physics")
system.activate( "multitouch" )
physics.start()
physics.pause()
local widget = require("widget")
local buttonGroup = display.newGroup()
local nameTable = {}
for i=1, 50 do
    nameTable[ #nameTable + 1] = "line"..i
end
--local gameObjects = display.newGroup()
local buildTable = {}
buildTable.buildReady = false
buildTable.objectPlaced = false
function getLength( a, b )
    local width, height = b.x-a.x, b.y-a.y
    return math.sqrt(width*width + height*height)
end
 
-- calculates the angle of a point from the 0,0. (When using atan2 the 0 degrees angle is actually pointing east.)
-- Input args: pt ... { x, y }
function AngleOfPoint( pt )
	local x, y = pt.x, pt.y
	local radian = math.atan2(y,x)
	local angle = radian*180/math.pi
	if angle < 0 then angle = 360 + angle end
	return angle
end
 
-- calculates the difference between two angles, but this accepts two points, not their angles
-- Input args: pointA, pointB ... { x, y }
-- Input args: clockwise ... true|false
function AngleDiff( pointA, pointB, clockwise )
	local angleA, angleB = AngleOfPoint( pointA ), AngleOfPoint( pointB )
	
	if angleA == angleB then
		return 0
	end
	
	if clockwise then
		if angleA > angleB then
			return angleA - angleB
			else
			return 360 - (angleB - angleA)
		end
	else
		if angleA > angleB then
			return angleB + (360 - angleA)
			else
			return angleB - angleA
		end
	end
	
end
 
--[[
 This creates a multi-touch tracking object and adds it to a list of multi-touch tracking objects
 internal to the image being manipulated by the touches.
 ]]--
function addTouch( img, event )
	
	--[[ Construction ]]--
	local touch = display.newCircle( event.x, event.y, 50 )
	touch:setFillColor( 255,0,0,150 )
	
	-- this data is required to be able to calculate the motion of the touches.
	-- basically, if you don't use this function to manage your multiple touch points, you need to
	-- manage this data yourself, so that the objects passed into the 'makePinchZoom' functions have it.
	-- the 'makePinchZoom' functions don't call the other args or functions added by this function.
	touch.xStart, touch.yStart = event.x, event.y
	touch.xPrev, touch.yPrev = event.x, event.y
	touch.x, touch.y = event.x, event.y
	
	touch.parentImg = img
	touch.id = event.id
	
	-- adds the list in which to keep the multi-touch tracking objects
	if (touch.parentImg.touchList == nil) then
		local list = {}
		
		function list:indexOf( touch )
			for i=1, #list do
				if (list[i] == touch) then
					return i
				end
			end
			return 0
		end
		
		touch.parentImg.touchList = list
	end
	
	touch.list = touch.parentImg.touchList
	touch.list[ #touch.list +1 ] = touch
 
	--[[ External functions ]]--
 
	function touch:isFirst()
		if (touch.list[1] == touch) then
			return true
		else
			return false
		end
	end
 
	function touch:indexOf()
		return touch.list:indexOf( touch )
	end
 
	--[[ Internal functions ]]--
	
	-- basically makes a record of the original event position
	function touch:began( event )
		-- should never be called, this is here for convenience, but should never be called
		touch.xStart, touch.yStart = event.x, event.y
	end
	
	-- moves the touch object and fires the image's touchMoved event listener
	function touch:moved( event )
		if (touch.parentImg.touchMoved ~= nil) then
			touch.xPrev, touch.yPrev = touch.x, touch.y
			touch.x, touch.y = event.x, event.y
			touch.parentImg:touchMoved( touch )
		end
	end
	
	-- removes the touch object
	function touch:endedCancelled( event )
		display.getCurrentStage():setFocus( touch, nil )
		table.remove( touch.list, touch:indexOf() )
		touch:removeSelf()
	end
	
	-- just calls other functions to deal with the events, to make the code cleaner
	function touch:touch( event )
		if (event.phase == "began") then
			touch:began( event )
		elseif (event.phase == "moved") then
			touch:moved( event )
		elseif (event.phase == "ended" or event.phase == "cancelled") then
			touch:endedCancelled( event )
		end
	end
 
	--[[ Completion ]]--
 
	touch:addEventListener( "touch", touch )
	display.getCurrentStage():setFocus( touch, event.id )
 
	return touch -- for convenience, but not really used
end
 
---
 
--[[
  Adds functions to the image to allow it to be pinch-zoom-able
  In short: this contains the functions that do the magic.
  If you want to rip the magic out, just take these functions, remove the 'img:' from their name,
  and make sure you are managing the x, y, and xPrev, yPrev values to be passed to these functions.
]]--
function makePinchZoom( img )
	-- sets the reference point to be the mid-point between the touches, relative to the img x,y
	function img:setReference( touchA, touchB )
		img.xPrevReference = img.xReference
		img.yPrevReference = img.yReference
		
		-- get touch mid-point relative to image
		local tax = img.x-(img.x - touchA.x)
		local tay = img.y-(img.y - touchA.y)
		local tbx = img.x-(img.x - touchB.x)
		local tby = img.x-(img.y - touchB.y)
		
		-- set the position (relative to the image's 0,0) around which scaling and rotation is performed
		-- see: http://developer.anscamobile.com/content/display-objects#object.xReference
		img.xReference = (tbx-tax)/2
		img.yReference = (tby-tay)/2
	end
 
	-- sets the reference back to it's original value, to avoid screwing with other code which may have used it
	-- this will usually be 0,0
	-- set: http://developer.anscamobile.com/content/display-objects#object.xReference
	function img:unsetReference()
		img.xReference = img.xPrevReference
		img.yReference = img.yPrevReference
		
		img.xPrevReference = nil
		img.yPrevReference = nil
	end
 
	-- moves the image relative to the amount the mid-point between the touches has moved
	function img:doMove( touchA, touchB )
		local x = ((touchA.x - touchA.xPrev) + (touchB.x - touchB.xPrev)) / 2
		local y = ((touchA.y - touchA.yPrev) + (touchB.y - touchB.yPrev)) / 2
		
		img.x = img.x + x
		img.y = img.y + y
	end
 
	-- rotates the image relative to how much the touch points have moved relative to each other
	function img:doRotate( touchA, touchB )
		local prev = AngleOfPoint( { x=touchB.xPrev-touchA.xPrev, y=touchB.yPrev-touchA.yPrev } )
		local current = AngleOfPoint( { x=touchB.x-touchA.x, y=touchB.y-touchA.y } )
		
		img.rotation = img.rotation + (current - prev)
	end
 
	-- scales the images relative to the previous and current distance between the two touch points
	function img:doScale( touchA, touchB )
		local prevLen = getLength( {x=touchA.xPrev, y=touchA.yPrev}, {x=touchB.xPrev, y=touchB.yPrev} )
		local currentLen = getLength( {x=touchA.x, y=touchA.y}, {x=touchB.x, y=touchB.y} )
		
		local scale = currentLen / prevLen
		
		img.xScale = img.xScale * scale
		img.yScale = img.yScale * scale
	end
	
	--[[
	  This is called by the addTouch functions above.
	  if you don't want to have my code managing the multi-touch points, you will have to track those
	  multi-touch events yourself and make sure you can pass the data objects into these functions.
	  all that this function really does is make sure there are at least 2 multi-touch points known in
	  the system and passes them in. If you want to do that yourself, just pass in objects with the data:
	  { x, y, xPrev, yPrev }
	  It is important to call the setReference and unsetReference functions because they manipulate the
	  x|yReference values. see: http://developer.anscamobile.com/content/display-objects#object.xReference
	]]--
	function img:touchMoved( touch )
		if (#img.touchList == 1) then
			img.x, img.y = img.x+(touch.x-touch.xPrev), img.y+(touch.y-touch.yPrev)
		elseif (#img.touchList == 2) then
			-- this is the section of code you need to call yourself if you decide to extract this code
			-- just make sure you always pass in: { x, y, xPrev, yPrev } for each arg
			img:setReference( img.touchList[1], img.touchList[2] )
			img:doMove( img.touchList[1], img.touchList[2] )
			img:doRotate( img.touchList[1], img.touchList[2] )
			img:doScale( img.touchList[1], img.touchList[2] )
			img:unsetReference()
		end
	end
end
local function isCollision( obj, obj2 )
			if obj2 == nil then
                return false
            else
                local cos = math.cos
                local sin = math.sin
                local asin = math.asin
                local sqrt = math.sqrt
                local rad = math.rad
                local pi = math.pi
                
                
                local x10 = obj.x
                local y10 = obj.y

                local r = obj.rotation
                obj.rotation = 0
                local height1 = obj._height/2
                local width1 = obj._width/2
                obj.rotation = r
                
                local radrot1 = rad(obj.rotation)

                local x20 = obj2.x
                local y20 = obj2.y

                r = obj2.rotation
                obj2.rotation = 0
                local height2 = obj2._height/2
                local width2 = obj2._width/2
                obj2.rotation = r
                
                local radrot2 = rad(obj2.rotation)


                local radius1 = sqrt( height1*height1 + width1*width1 )
                local radius2 = sqrt( height2*height2 + width2*width2 )




                local radius1 = sqrt( height1*height1 + width1*width1 )
                local radius2 = sqrt( height2*height2 + width2*width2 )

                local angle1 = asin( height1 / radius1 )
                local angle2 = asin( height2 / radius2 )

                local x1 = {}; local y1 = {}
                local x2 = {}; local y2 = {}

                x1[1] = x10 + radius1 * cos(radrot1 - angle1); y1[1] = y10 + radius1 * sin(radrot1 - angle1)
                x1[2] = x10 + radius1 * cos(radrot1 + angle1); y1[2] = y10 + radius1 * sin(radrot1 + angle1)
                x1[3] = x10 + radius1 * cos(radrot1 + pi - angle1); y1[3] = y10 + radius1 * sin(radrot1 + pi - angle1)
                x1[4] = x10 + radius1 * cos(radrot1 + pi + angle1); y1[4] = y10 + radius1 * sin(radrot1 + pi + angle1)

                x2[1] = x20 + radius2 * cos(radrot2 - angle2); y2[1] = y20 + radius2 * sin(radrot2 - angle2)
                x2[2] = x20 + radius2 * cos(radrot2 + angle2); y2[2] = y20 + radius2 * sin(radrot2 + angle2)
                x2[3] = x20 + radius2 * cos(radrot2 + pi - angle2); y2[3] = y20 + radius2 * sin(radrot2 + pi - angle2)
                x2[4] = x20 + radius2 * cos(radrot2 + pi + angle2); y2[4] = y20 + radius2 * sin(radrot2 + pi + angle2)

                local axisx = {}; local axisy = {}

                axisx[1] = x1[1] - x1[2]; axisy[1] = y1[1] - y1[2]
                axisx[2] = x1[3] - x1[2]; axisy[2] = y1[3] - y1[2]

                axisx[3] = x2[1] - x2[2]; axisy[3] = y2[1] - y2[2]
                axisx[4] = x2[3] - x2[2]; axisy[4] = y2[3] - y2[2]

                for k = 1,4 do

                    local proj = x1[1] * axisx[k] + y1[1] * axisy[k]

                    local minProj1 = proj
                    local maxProj1 = proj

                    for i = 2,4 do
                        proj = x1[i] * axisx[k] + y1[i] * axisy[k]

                        if proj < minProj1 then
                            minProj1 = proj
                        elseif proj > maxProj1 then
                            maxProj1 = proj
                        end

                    end

                    proj = x2[1] * axisx[k] + y2[1] * axisy[k]

                    local minProj2 = proj
                    local maxProj2 = proj

                    for j = 2,4 do
                        proj = x2[j] * axisx[k] + y2[j] * axisy[k]

                        if proj < minProj2 then
                            minProj2 = proj
                        elseif proj > maxProj2 then
                            maxProj2 = proj
                        end

                    end

                    if maxProj2 < minProj1 or maxProj1 < minProj2 then
                        return false
                    end
                end

                return true
            end
end
local function rounding( value )
    if (10 <= value) and (value < 30) then
     value = 10
    elseif (30 <= value) and (value < 50) then
     value = 40
    elseif (50 <= value and value < 70) then
     value = 60
    elseif (70 <= value and value < 90) then 
     value = 80
    elseif (90 <= value and value < 110) then
     value = 100
    elseif (110 <= value) and (value < 130) then
     value = 120
    elseif (130 <= value and value < 150) then
     value = 140
    elseif (150 <= value and value < 170) then 
     value = 160
    elseif (170 <= value and value < 190) then
     value = 180
    else 
     value = 200
    end
    return value
end
local k = 1
math.randomseed( os.time())
local x = 1
local lattia = display.newRect(0, display.actualContentHeight- 50, 5000, 10)
local valueTable = {}
valueTable.width = 100
valueTable.height = 10
valueTable.rotation = 0
valueTable.alpha = 0.5
local angle = (math.pi/2)
local buttonBackground = display.newRect(250, display.actualContentHeight- 20, 600, 50)
buttonBackground:setFillColor( 0,0,1)
buttonBackground:toBack()
physics.addBody(lattia, "static", { friction=0.5, bounce=0.3 })
lattia:toBack()
--gameObjects:insert(lattia)
local function decrease(event)
    if event.phase == "ended" and (nameTable[x-1].width > 20) then
        valueTable.width = valueTable.width - 20
        nameTable[x-1].width = valueTable.width
        nameTable[x-1]._height = valueTable.height
        nameTable[x-1]._width = valueTable.width
        nameTable[x-1]:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
end
local function increase(event)
    if event.phase == "ended" and (nameTable[x-1].width < 300) then
        valueTable.width = valueTable.width + 20
        nameTable[x-1].width = valueTable.width
        nameTable[x-1]._height = valueTable.height
        nameTable[x-1]._width = valueTable.width
        nameTable[x-1]:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
end
local function rotation(event)
    if event.phase == "ended" then
        valueTable.rotation = valueTable.rotation + 15
        nameTable[x-1].rotation = valueTable.rotation
        angle = angle + (math.pi/12)
        nameTable[x-1]:setFillColor(250, 250, 250, 100)        
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
    return angle
end
local function rotation2(event)
    if event.phase == "ended" then
        valueTable.rotation = valueTable.rotation - 15
        nameTable[x-1].rotation = valueTable.rotation
        angle = angle - (math.pi/12)
        nameTable[x-1]:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
    return angle
end
local function increaseH(event)
    if event.phase == "ended" and (nameTable[x-1].height < 30) then
        valueTable.height = valueTable.height + 10
        nameTable[x-1].height = valueTable.height
        nameTable[x-1]._height = valueTable.height
        nameTable[x-1]._width = valueTable.width
        nameTable[x-1]:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
end
local function decreaseH(event)
    if event.phase == "ended" and (nameTable[x-1].height > 10) then
        valueTable.height = valueTable.height - 10
        nameTable[x-1].height = valueTable.height
        nameTable[x-1]._height = valueTable.height
        nameTable[x-1]._width = valueTable.width
        nameTable[x-1]:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(nameTable[x-1], nameTable[i]) then
                            nameTable[x-1]:setFillColor(250, 0, 0)
                        end
                    end
                end
        if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - nameTable[x-1].y) and (nameTable[x-1].alpha <= 0.9) then
            nameTable[x-1]:setFillColor(250, 0, 0)
        end
    end
end
local function undo(event)
    if (event.phase == "ended") and (nameTable[x-k] ~= nil) then
        display.remove( nameTable[x-k] )
        nameTable[x-k] = nil
        k = k + 1
    elseif (event.phase == "ended") and (nameTable[x-k] == nil) then
        repeat
            k = k + 1
            display.remove(nameTable[x-k])
        until((nameTable[x-k] ~= nil ) or ((x-k) < 0))
        nameTable[x-k] = nil
        k = 1
    end
    return k
end
local function reset(event)
    if (event.phase == "ended") then
        for a=x, 0, -1 do
            display.remove( nameTable[a])
            nameTable[a] = nil
        end
        x = 1
        return x
    end
end
local function clockU()
    --gameObjects.y = gameObjects.y + 1
    for i=1, (x-2) do
        if nameTable[i] ~= nil then
            nameTable[i].y = nameTable[i].y + 1
            nameTable[i]._height = nameTable[i].height
            nameTable[i]._width = nameTable[i].width
        end
    end
        

        lattia.y = lattia.y + 1

end
local function clockR()
    --gameObjects.x = gameObjects.x - 1
        for i=1, (x-2) do
            if nameTable[i] ~= nil then
                nameTable[i].x = nameTable[i].x - 1
                nameTable[i]._height = nameTable[i].height
                nameTable[i]._width = nameTable[i].width
            end
    
        end
        if nameTable[x-2] ~= nil then
        end

end
local function clockL()
    --gameObjects.x = gameObjects.x + 1
        for i=1, (x-2) do
            if nameTable[i] ~= nil then
                nameTable[i].x = nameTable[i].x + 1
                nameTable[i]._height = nameTable[i].height
                nameTable[i]._width = nameTable[i].width
            end
        end

end
local function clockD()
    if lattia.y > display.actualContentHeight - 50 then
        --gameObjects.y = gameObjects.y - 1
        lattia.y = lattia.y - 1
            for i=1, (x-2) do
                if nameTable[i] ~= nil then
                    nameTable[i].y = nameTable[i].y - 1
                    nameTable[i]._height = nameTable[i].height
                    nameTable[i]._width = nameTable[i].width
                end
            end
    end
end
local timerPaused = true
local timerPaused2 = true
local timerPaused3 = true
local timerPaused4 = true
local opk = timer.performWithDelay(50, clockU, 0)
timer.pause( opk )
local opkh = timer.performWithDelay(50, clockR, 0)
timer.pause( opkh )
local opkhp = timer.performWithDelay(50, clockL, 0)
timer.pause( opkhp )
local opkhpk = timer.performWithDelay(50, clockD, 0)
timer.pause( opkhpk )
local function move(event)
    local target = event.target
	if buildTable.buildReady == false then

		if event.phase == "began" then
			display.getCurrentStage():setFocus(target)
			target.hasFocus = true
			positionx = target.x
			positiony = target.y
			return true
		elseif (target.hasFocus) then
			if event.phase == "moved" and ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) <= (display.actualContentHeight- 55) - event.target.y) and (target.alpha <= 0.9) then
				target.x, target.y = (event.x - event.xStart + positionx), (event.y - event.yStart + positiony)
                if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 55) - event.target.y) then
                    event.target:toBack()
                    print("moi8")
                end    
                event.target:setFillColor(250, 250, 250, 100)
                event.target:toBack()
                for i =1, (x-2), 1 do
                    if (nameTable[i] ~= nil) and (nameTable[i] ~= event.target) then
                        if isCollision(event.target, nameTable[i]) then
                            event.target:setFillColor(250, 0, 0)
                            print("moi4")
                            nameTable[i]:toBack()
                        end
                    end
                end
                if event.target.y < 50 then
                    if timerPaused == true then
                        timer.resume( opk )
                        timerPaused = false
                    end
                
                else 
                    if timerPaused == false then
                        timer.pause( opk )
                        timerPaused = true
                    end
                end
                if event.target.x > display.viewableContentWidth - 50 then
                        if timerPaused2 == true then
                            timer.resume( opkh )
                            timerPaused2 = false
                        end
                else
                    if timerPaused2 == false then
                            timer.pause( opkh )
                            timerPaused2 = true
                    end
                end
                if event.target.x < 50 then
                        if timerPaused3 == true then
                            timer.resume( opkhp )
                            timerPaused3 = false
                        end
                else
                    if timerPaused3 == false then
                            timer.pause( opkhp )
                            timerPaused3 = true
                    end
                end
                if event.target.y > display.viewableContentHeight - 70 then
                        if timerPaused4 == true then
                            timer.resume( opkhpk )
                            timerPaused4 = false
                        end
                else
                    if timerPaused4 == false then
                            timer.pause( opkhpk )
                            timerPaused4 = true
                    end
                end
                if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 55) - event.target.y) and ((event.y - event.yStart) < 0) and (target.alpha <= 0.9) then
                    event.target:setFillColor(250, 0, 0)
                    print("moi3")
                end
			elseif event.phase == "moved" and ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 55) - event.target.y) and ((event.y - event.yStart) < 0) and (target.alpha <= 0.9) then
				target.x, target.y = (event.x - event.xStart + positionx), (event.y - event.yStart + positiony)
                event.target:setFillColor(250, 0, 0)
                if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 55) - event.target.y) then
                    event.target:toBack()
                    print("moi7")
                end  
                print("moi2")
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(event.target, nameTable[i]) then
                            event.target:setFillColor(250, 0, 0)
                            print("moi1")
                        end
                    end
                end
			elseif event.phase == "ended" or event.phase == "cancelled" then
				if ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 52.5) - event.target.y) and (target.alpha <= 0.9) then 
                    event.target:setFillColor(250, 0, 0)
                    print("moi")
                --else
                    --event.target:setFillColor(250,250,250,100)
                end
                display.getCurrentStage():setFocus(nil)
				target.hasFocus = false
                timer.pause( opk )
                timer.pause( opkh )
                timer.pause( opkhp )
				for i=1, (x-2) do
					if nameTable[i] ~= nil and nameTable[i] ~= event.target then
						if ( isCollision( event.target, nameTable[i] )) then
							event.target:setFillColor(250,0,0)
                            print("hei")
                            nameTable[i]:toBack()
						end
					end
				end
			end
			return true
		end
		return false
	end
end
local function materiaaliNappi(event)
   if event.phase == "ended" then
        buildTable.objectPlaced = true
        button16:removeSelf()
        button16 = nil
        physicsButton:removeSelf()
        physicsButton = nil
		undoButton:removeSelf()
        undoButton = nil
		resetButton:removeSelf()
        resetButton= nil
        button1 = widget.newButton(
            {
                left = display.viewableContentWidth - 500,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = decrease
            }
        ) 
        buttonGroup:insert(button1)  
        button2 = widget.newButton(
            {
                left = display.viewableContentWidth - 440,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = increase
            }
        )
        buttonGroup:insert(button2)
        button3 = widget.newButton(
            {
                left = display.viewableContentWidth - 360,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = rotation
            }
        )
        buttonGroup:insert(button3) 
        button4 = widget.newButton(
            {
                left = display.viewableContentWidth - 300,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = rotation2
            }
        )
        buttonGroup:insert(button4) 
        button5 = widget.newButton(
            {
                left = display.viewableContentWidth - 220,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = decreaseH
            }
        )
        buttonGroup:insert(button5) 
        button6 = widget.newButton(
            {
                left = display.viewableContentWidth - 160,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = increaseH
            }
        )
        buttonGroup:insert(button6)
        button7 = widget.newButton(
            {
                left = display.viewableContentWidth - 20,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = done
            }
        )
        buttonGroup:insert(button7)
        --if nameTable[x-1] ~= nil then
            --gameObjects:insert(nameTable[x-1])
        --end
        nameTable[x] = display.newRect(250, 100, valueTable.width, valueTable.height)
        valueTable.rotation = 0
		angle = (math.pi/2)
		nameTable[x].rotation = valueTable.rotation
        nameTable[x].alpha = valueTable.alpha
        nameTable[x]:toFront()
        nameTable[x]._height = nameTable[x].height
        nameTable[x]._width = nameTable[x].width
            for i=1, x do
                if x ~= i then
                    if isCollision(nameTable[x], nameTable[i]) == true then
                        nameTable[x]:setFillColor(250,0,0)
                    end
                end
            end
		k = 1
        x = x + 1
        nameTable[x-1]:addEventListener("touch", move)
    end
    return x
end
local function setPhysics( event )
    if (event.phase == "ended") then
			physics.start()
			buildTable.buildReady = true
            for i=1, (x-1) do
				if nameTable[i] ~= nil then
					if nameTable[i].alpha >= 0.6 then
					physics.addBody(nameTable[i], "dynamic", {density=10.0, bounce=0, friction=0.8})
					end
				end
            end
			return buildTable
    end
end
local function materialButton1()
    button16 = widget.newButton(
            {
                left = display.viewableContentWidth - 500,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = materiaaliNappi
            }
        )
            physicsButton = widget.newButton(
            {
                left = display.viewableContentWidth - 50,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = setPhysics
            }
        )
		           undoButton = widget.newButton(
            {
                left = display.viewableContentWidth - 100,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = undo
            }
		)
		           resetButton = widget.newButton(
            {
                left = display.viewableContentWidth - 160,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.jpg",
                onEvent = reset
            }
			
        )
end
local crash = false
function done(event)
    if (event.phase == "ended") and (((math.abs(((math.abs(valueTable.height * math.cos((math.pi / 2)- angle))) + valueTable.width * (math.abs(math.cos(angle)))) / 2)) <= (display.actualContentHeight- 52.5) - nameTable[x-1].y)) then
		for i=1, (x-2) do
            if ((x-1) ~= i) then
				if ( isCollision( nameTable[x-1], nameTable[i] )) == true then
                    crash = true
				end
            end
		end
        if crash == false then
        
							nameTable[x-1].alpha = 1.0
                            for i=1, (x-1) do
                                makePinchZoom( nameTable[i] )
                            end
							buttonGroup:removeSelf()
							buttonGroup = nil
							buttonGroup = display.newGroup()
                            nameTable[x-1]:toBack()
							materialButton1()
                            buildTable.objectPlaced = false
        end
        crash = false
    end
    return crash
end
materialButton1()