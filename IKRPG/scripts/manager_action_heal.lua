-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- NOTE 1: Only apply healing effect modifiers when healing surge involved, per Wizards customer service

function onInit()
	ActionsManager.registerActionIcon("heal", "action_heal");
	ActionsManager.registerTargetingHandler("heal", onTargeting);
	ActionsManager.registerModHandler("heal", modHeal);
	ActionsManager.registerResultHandler("heal", onHeal);
end

function onTargeting(rSource, rRolls)
	if #rRolls == 1 then
		if string.match(rRolls[1].sDesc, "%[SELF%]") then
			return { { rSource } };
		end
	end
	
	return { TargetingManager.getFullTargets(rSource) };
end

function getRoll(rActor, rAction)
	-- Create basic roll
	local rRoll = {};
	rRoll.aDice = {};
	rRoll.nMod = 0;

	-- Build the description
	rRoll.sDesc = "[HEAL";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. rAction.name;

	-- Iterate through clauses
	local nHealCost = 0;
	local nHSVMult = 0;
	local sHealType = "";
	for k, v in pairs(rAction.clauses) do
		-- Add dice and modifier to roll
		local aClauseDice, nClauseMod = StringManager.convertStringToDice(v.dicestr);
		for _, vDie in pairs(aClauseDice) do
			table.insert(rRoll.aDice, vDie);
		end
		rRoll.nMod = rRoll.nMod + nClauseMod;

		-- Add ability bonus modifiers
		for _,vStat in pairs(v.stat) do
			rRoll.nMod = rRoll.nMod + ActorManager.getAbilityBonus(rActor, vStat);
		end
		
		-- Add healing surge costs
		nHealCost = nHealCost + v.cost;
		
		-- Add healing surge multipliers
		nHSVMult = nHSVMult + v.basemult;
		
		-- For healing, just take the last type
		sHealType = v.subtype;
	end
	
	-- Add in roll properties
	if nHealCost ~= 0 then
		rRoll.sDesc = rRoll.sDesc .. " [COST " .. nHealCost .. "]";
	end
	if nHSVMult ~= 0 then
		rRoll.sDesc = rRoll.sDesc .. " [HSV " ..  nHSVMult .. "]";
	end
	if sHealType == "temp" then
		rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
	end
	if rAction.sTargeting == "self" then
		rRoll.sDesc = rRoll.sDesc .. " [SELF]";
	end

	return rRoll;
end

function performRoll(draginfo, rActor, rAction, rFocus)
	local rRoll = getRoll(rActor, rAction, rFocus);
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "heal", rRoll, nil, true);
end

function modHeal(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	local bTemp = string.match(rRoll.sDesc, "%[TEMP%]");
	local nHSVMult = tonumber(string.match(rRoll.sDesc, "%[HSV (%d+)%]")) or 0;
	
	if rSource and not bTemp and nHSVMult > 0 then
		local aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"HEAL"});
		if nEffectCount > 0 then
			for _,vDie in ipairs(aAddDice) do
				table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
			end
			rRoll.nMod = rRoll.nMod + nAddMod;

			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			rRoll.sDesc = rRoll.sDesc .. " " .. sEffects;
		end
	end
end

function onHeal(rSource, rTarget, rRoll)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	
	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		if not string.match(rRoll.sDesc, "%[SPECIFIC") then
			bShowMsg = false;
		end
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end
	
	local nTotal = ActionsManager.total(rRoll);
	ActionDamage.notifyApplyDamage(rSource, rTarget, rMessage.text, nTotal);
end
