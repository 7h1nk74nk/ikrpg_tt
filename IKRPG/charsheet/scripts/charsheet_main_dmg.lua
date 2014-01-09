--#########################
--DAMAGE TICKBOXES
--#########################
--script by someone
--worked over by DRLINE&&TT
--#########################


--wariables
local boxes_PHY,boxes_AGI,boxes_INT = {},{},{}

--wrapper
local getDNC = function(sNam,sTyp) return window.getDatabaseNode().getChild(sNam,sTyp) end	



--the rest
onInit = function()
	
	local nodeStats = getDNC("stats");
	if nodeStats then nodeStats.onChildUpdate = onSourceUpdate end --INSTALL HANDLER(onSourceUpdate): called when anything in the stats pane is updated
	
	table.insert(boxes_PHY,window.vitality_phy1);
	table.insert(boxes_PHY,window.vitality_phy2);
	table.insert(boxes_PHY,window.vitality_phy3);
	table.insert(boxes_PHY,window.vitality_phy4);
	table.insert(boxes_PHY,window.vitality_phy5);
	table.insert(boxes_PHY,window.vitality_phy6);
	table.insert(boxes_PHY,window.vitality_phy7);
	table.insert(boxes_PHY,window.vitality_phy8);
	table.insert(boxes_PHY,window.vitality_phy9);
	table.insert(boxes_PHY,window.vitality_phy10);
	
	table.insert(boxes_AGI,window.vitality_agi1);
	table.insert(boxes_AGI,window.vitality_agi2);
	table.insert(boxes_AGI,window.vitality_agi3);
	table.insert(boxes_AGI,window.vitality_agi4);
	table.insert(boxes_AGI,window.vitality_agi5);
	table.insert(boxes_AGI,window.vitality_agi6);
	table.insert(boxes_AGI,window.vitality_agi7);
	table.insert(boxes_AGI,window.vitality_agi8);
	table.insert(boxes_AGI,window.vitality_agi9);
	table.insert(boxes_AGI,window.vitality_agi10);
	
	table.insert(boxes_INT,window.vitality_int1);
	table.insert(boxes_INT,window.vitality_int2);
	table.insert(boxes_INT,window.vitality_int3);
	table.insert(boxes_INT,window.vitality_int4);
	table.insert(boxes_INT,window.vitality_int5);
	table.insert(boxes_INT,window.vitality_int6);
	table.insert(boxes_INT,window.vitality_int7);
	table.insert(boxes_INT,window.vitality_int8);
	table.insert(boxes_INT,window.vitality_int9);
	table.insert(boxes_INT,window.vitality_int10);
	
	for count=1,10 do  								--INSTALL HANDLER(checkDamage): called when tickboxes are updated
		getDNC(boxes_PHY[count].getName(),"number").onUpdate=checkDamage;                            
		getDNC(boxes_AGI[count].getName(),"number").onUpdate=checkDamage;
		getDNC(boxes_INT[count].getName(),"number").onUpdate=checkDamage;
	end

	onSourceUpdate("onInitCall");
	
end

onSourceUpdate = function(source) 
	--print("damagepane onSourceUpdate: "..tostring(source))
	updateVitality() 
end

updateVitality = function(resetboxes)
	--load stats
	local PHY,AGI,INT = window.phy_score.getDatabaseNode().getValue(),
						window.agi_score.getDatabaseNode().getValue(),
						window.int_score.getDatabaseNode().getValue()
	--
	
	for count=1,10 do             
		local newIndex = 0
		
		if not resetboxes then newIndex = boxes_PHY[count].getIndex() else newIndex = 0 end
		if count > PHY or PHY == 0 then                                                       
			boxes_PHY[count].setColor("ff606060")
			boxes_PHY[count].setIndex(0)
			boxes_PHY[count].setReadOnly(true)
		else
			boxes_PHY[count].setColor("ff0000ff")
			boxes_PHY[count].setIndex(newIndex)
			boxes_PHY[count].setReadOnly(false)
		end
		
		if not resetboxes then newIndex = boxes_AGI[count].getIndex() else newIndex = 0 end
		if count > AGI or AGI == 0 then                            
			boxes_AGI[count].setColor("ff606060")
			boxes_AGI[count].setIndex(0)
			boxes_AGI[count].setReadOnly(true)
		else
			boxes_AGI[count].setColor("ffff0000")
			boxes_AGI[count].setIndex(newIndex)
			boxes_AGI[count].setReadOnly(false)
		end
		
		if not resetboxes then newIndex = boxes_INT[count].getIndex() else newIndex = 0 end
		if count > INT or INT == 0 then                                                        
			boxes_INT[count].setColor("ff606060")
			boxes_INT[count].setIndex(0)
			boxes_INT[count].setReadOnly(true) 
		else
			boxes_INT[count].setColor("ff00aa00")
			boxes_INT[count].setIndex(newIndex)
			boxes_INT[count].setReadOnly(false) 
		end                                                                                                                                      
	end
	
	checkDamage("updateVitCall") --AVAILIABLE TICKBOXES UPDATED, TIME TO UPDATE THE DAMAGE COUNTERS/WARNINGS
	
end

checkDamage = function(source)	
	--load stats
	local PHY,AGI,INT = window.phy_score.getDatabaseNode().getValue(),
						window.agi_score.getDatabaseNode().getValue(),
						window.int_score.getDatabaseNode().getValue()
	--tempvars
	local damage_PHY,damage_AGI,damage_INT = 0,0,0

	
	
	--count damage
	for count=1,10 do
		if boxes_PHY[count].getIndex() == 1 then damage_PHY = damage_PHY + 1 end
		if boxes_AGI[count].getIndex() == 1 then damage_AGI = damage_AGI + 1 end
		if boxes_INT[count].getIndex() == 1 then damage_INT = damage_INT + 1 end
	end
	
	---[[ partyscreen code
	window.damage_PHY.getDatabaseNode().setValue(damage_PHY)
	window.damage_AGI.getDatabaseNode().setValue(damage_AGI)
	window.damage_INT.getDatabaseNode().setValue(damage_INT)
	
	print("damage_PHY: "..tostring(window.damage_PHY.getDatabaseNode().getValue()).." "..tostring(damage_PHY));
	print("damage_AGI: "..tostring(window.damage_AGI.getDatabaseNode().getValue()).." "..tostring(damage_AGI));
	print("damage_INT: "..tostring(window.damage_INT.getDatabaseNode().getValue()).." "..tostring(damage_INT));
	--]]
	
	--show warnings if necessary
	if damage_PHY == PHY then window.warning_phy.setVisible(true) else window.warning_phy.setVisible(false) end
	if damage_AGI == AGI then window.warning_agi.setVisible(true) else window.warning_agi.setVisible(false) end
	if damage_INT == INT then window.warning_int.setVisible(true) else window.warning_int.setVisible(false) end
	if damage_PHY == PHY and damage_AGI == AGI and damage_INT == INT then window.incapacitated.setVisible(true) else window.incapacitated.setVisible(false) end

	
	
	--extra stuff
	--[[ print debug info: damage numbers
	local PHYMAX,AGIMAX,INTMAX = window.phy_max.getDatabaseNode().getValue(),
								 window.agi_max.getDatabaseNode().getValue(),
								 window.int_max.getDatabaseNode().getValue()
	--
	print("PHY DAMAGE: "..tostring(damage_PHY).." / "..tostring(PHYMAX))
	print("AGI DAMAGE: "..tostring(damage_AGI).." / "..tostring(AGIMAX))
	print("INT DAMAGE: "..tostring(damage_INT).." / "..tostring(INTMAX))
	--]]
	
	---[[ print debug info: boxes table ids
	for i=1,10 do
		if source == getDNC(boxes_PHY[i].getName(), "number") then print("boxes_PHY["..i.."]") end
		if source == getDNC(boxes_AGI[i].getName(), "number") then print("boxes_AGI["..i.."]") end
		if source == getDNC(boxes_INT[i].getName(), "number") then print("boxes_INT["..i.."]") end
	end
	--]]	


end