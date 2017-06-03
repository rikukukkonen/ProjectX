local physics = require("physics")
physics.start()
physics.pause()
local widget = require("widget")
local buttonGroup = display.newGroup()
local nameTable = {}
for i=1, 50 do
    nameTable[ #nameTable + 1] = "line"..i
end
local lineGroup = display.newGroup()
local gameObjects = display.newGroup()
local buildTable = {}
buildTable.buildReady = false
buildTable.objectPlaced = false
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
physics.addBody(lattia, "static", { friction=0.5, bounce=0.3 })
gameObjects:insert(lattia)
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
    end
end
local angle = (math.pi/2)
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
local rikunIdea = false
local function clock()
    if rikunIdea == true then
        gameObjects.y = gameObjects.y -1 
    end
end
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
                event.target:setFillColor(250, 250, 250, 100)
                for i =1, (x-2), 1 do
                    if nameTable[i] ~= nil then
                        if isCollision(event.target, nameTable[i]) then
                            event.target:setFillColor(250, 0, 0)
                        end
                    end
                end
                if event.target.y < 50 then
                    tmr = timer.performWithDelay(1000, clock, 0)
                    rikunIdea = true 
                elseif rikunIdea == true and event.target.y >= 50 then
                    timer.cancel(tmr)
                    rikunIdea = false
                end

			elseif event.phase == "moved" and ((math.abs(((math.abs(nameTable[x-1].height * math.cos((math.pi / 2)- angle))) + nameTable[x-1].width * (math.abs(math.cos(angle)))) / 2)) > (display.actualContentHeight- 55) - event.target.y) and ((event.y - event.yStart) < 0) and (target.alpha <= 0.9) then
				target.x, target.y = (target.x), (event.y - event.yStart + positiony)
                event.target:setFillColor(250, 250, 250, 100)
                for i =1, (x-2) do
                    if nameTable[i] ~= nil then
                        if isCollision(event.target, nameTable[i]) then
                            event.target:setFillColor(250, 0, 0)
                        end
                    end
                end
			elseif event.phase == "ended" or event.phase == "cancelled" then
				event.target:setFillColor(250,250,250,100)
                display.getCurrentStage():setFocus(nil)
				target.hasFocus = false
				for i=1, (x-2) do
					if nameTable[i] ~= nil then
						if ( isCollision( event.target, nameTable[i] )) then
							transition.to( event.target, {time=200, x=positionx, y=positiony} )
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
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
                defaultFile = "butterfly.png",
                onEvent = done
            }
        )
        buttonGroup:insert(button7)
        nameTable[x] = display.newRect(250, 100, valueTable.width, valueTable.height)
        valueTable.rotation = 0
		angle = (math.pi/2)
		nameTable[x].rotation = valueTable.rotation
        nameTable[x].alpha = valueTable.alpha
        lineGroup:insert(nameTable[x])
        if nameTable[x-1] ~= nil then
            gameObjects:insert(nameTable[x-1])
        end
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
                defaultFile = "butterfly.png",
                onEvent = materiaaliNappi
            }
        )
            physicsButton = widget.newButton(
            {
                left = display.viewableContentWidth - 50,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.png",
                onEvent = setPhysics
            }
        )
		           undoButton = widget.newButton(
            {
                left = display.viewableContentWidth - 100,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.png",
                onEvent = undo
            }
		)
		           resetButton = widget.newButton(
            {
                left = display.viewableContentWidth - 160,
                top = display.viewableContentHeight- 45 ,
                width = 40,
                height = 40,
                defaultFile = "butterfly.png",
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
							buttonGroup:removeSelf()
							buttonGroup = nil
							buttonGroup = display.newGroup()
                            nameTable[x-1]:toFront()
							materialButton1()
                            buildTable.objectPlaced = false
        end
        crash = false
    end
    return crash
end
materialButton1()