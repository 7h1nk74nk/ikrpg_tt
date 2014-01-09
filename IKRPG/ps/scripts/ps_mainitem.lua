-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- onLevelChanged();
	-- onXPChanged();
	-- onHPChanged();
	onphy_scoreChanged();
	onagi_scoreChanged();
	onint_scoreChanged();
end

-- function onLevelChanged()
	-- local nLevel = level.getValue();
	-- if nLevel > 20 then
		-- class.setVisible(false);
		-- paragon.setVisible(false);
		-- epic.setVisible(true);
	-- elseif nLevel > 10 then
		-- class.setVisible(false);
		-- paragon.setVisible(true);
		-- epic.setVisible(false);
	-- else
		-- class.setVisible(true);
		-- paragon.setVisible(false);
		-- epic.setVisible(false);
	-- end
-- end

-- function onXPChanged()
	-- local nExp = exp.getValue();
	-- local nExpNeeded = expneeded.getValue();
	
	-- local sToolText = "";
	-- local nPercentNextLevel = 0;
	-- if TableManager and TableManager.findTable("Character Advancement") then
		-- local nLevel = level.getValue();
		-- if nLevel < 1 then
			-- nLevel = 1;
		-- end
		
		-- local nRelXPTotal = 0;
		-- local nRelXPNextLevel = 0;
		-- local lookupCurrLevelXPTotal = TableManager.lookup("Character Advancement", nLevel, "Total XP");
		-- local lookupNexttLevelXPTotal = TableManager.lookup("Character Advancement", nLevel + 1, "Total XP");	
		-- if lookupCurrLevelXPTotal and lookupNexttLevelXPTotal then
			-- lookupCurrLevelXPTotal = string.gsub(lookupCurrLevelXPTotal, ",", "");
			-- lookupNexttLevelXPTotal = string.gsub(lookupNexttLevelXPTotal, ",", "");
			
			-- nRelXPTotal = nExp - tonumber(lookupCurrLevelXPTotal);
			-- nRelXPNextLevel = tonumber(lookupNexttLevelXPTotal) - tonumber(lookupCurrLevelXPTotal);
		-- end

		-- sToolText = "Relative XP: ";
		-- nExp = nRelXPTotal;
		-- nExpNeeded = nRelXPNextLevel;
	-- else
		-- sToolText = "XP: ";
	-- end
	
	-- xpbar.setMax(nExpNeeded);
	-- xpbar.setValue(nExp);
	-- sToolText = sToolText .. tostring(nExp) .. " / " .. tostring(nExpNeeded);
	-- xpbar.updateText(sToolText);
	
	-- if (nExpNeeded > 0) and ((nExp / nExpNeeded) >= .75) then
		-- xpbar.updateBackColor("990000");
	-- else
		-- xpbar.updateBackColor("0F0B0B");
	-- end
-- end



-- function onHPChanged()
	-- local nHP = hptotal.getValue();
	-- local nWounds = wounds.getValue();
	-- local nPercentWounded = 0;
	-- if nHP > 0 then
		-- nPercentWounded = nWounds / nHP;
	-- end
	
	-- if nPercentWounded <= 0 then
		-- hpbar.updateBackColor("000099");
	-- elseif nPercentWounded < .25 then
		-- hpbar.updateBackColor("006600");
	-- elseif nPercentWounded < .5 then
		-- hpbar.updateBackColor("CC6600");
	-- elseif nPercentWounded < .75 then
		-- hpbar.updateBackColor("990000");
	-- elseif nPercentWounded < 1 then
		-- hpbar.updateBackColor("0F0B0B");
	-- else
		-- hpbar.updateBackColor("828182");
	-- end
	
	-- hpbar.setMax(nHP);
	-- hpbar.setValue(nHP - nWounds);
	-- hpbar.updateText("HP: " .. (nHP - nWounds) .. " / " .. nHP);
-- end


function onphy_scoreChanged()
	local nPHYMax = Physique.getValue();
	local nPHYUsed = Poise.getValue();
	local nPercentPHY = 0;
	if nPHYMax > 0 then
		nPercentPHY = nPHYUsed / nPHYMax;
	end
	
	phybar.setMax(nPHYMax);
	phybar.setValue(nPHYMax - nPHYUsed);
	phybar.updateText("Vitality: " .. nPHYUsed .. " / " .. nPHYMax);
end

function onagi_scoreChanged()
	local nAGIMax = Agility.getValue();
	local nAGIUsed = Poise.getValue();
	local nPercentAGI = 0;
	if nAGIMax > 0 then
		nPercentAGI = nAGIUsed / nAGIMax;
	end
	
	agibar.setMax(nAGIMax);
	agibar.setValue(nAGIMax - nAGIUsed);
	agibar.updateText("Vitality: " .. nAGIUsed .. " / " .. nAGIMax);
end

function onint_scoreChanged()
	local nINTMax = Intellect.getValue();
	local nINTUsed = Poise.getValue();
	local nPercentINT = 0;
	if nINTMax > 0 then
		nPercentINT = nINTUsed / nINTMax;
	end
	
	intbar.setMax(nINTMax);
	intbar.setValue(nINTMax - nINTUsed);
	intbar.updateText("Vitality: " .. nINTUsed .. " / " .. nINTMax);
end
