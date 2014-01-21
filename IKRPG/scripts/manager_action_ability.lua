-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerActionIcon("ability", "action_roll");
	ActionsManager.registerModHandler("ability", modRoll);
	ActionsManager.registerResultHandler("ability", onRoll);
end

function performRoll(draginfo, rActor, sAbilityStat, nTargetDC, bSecretRoll, bAddName)
	local rRoll = {};
	
	-- SETUP
	rRoll.aDice = { "d6","d6" };
	rRoll.nMod = ActorManager.getAbilityBonus(rActor, sAbilityStat);
	rRoll.nMod = rRoll.nMod + ActorManager.getAbilityBonus(rActor, "halflevel");
	
	-- BUILD THE OUTPUT
	Debug.console(sAbilityStat)
	printstack()
	rRoll.sDesc = "[ABILITY]";
	rRoll.sDesc = rRoll.sDesc .. " " .. StringManager.capitalize(sAbilityStat);
	rRoll.sDesc = rRoll.sDesc .. " check";
	
	if bAddName then
		rRoll.sDesc = "[ADDNAME] " .. rRoll.sDesc;
	end
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	
	local rCustom = {};
	if nTargetDC then
		table.insert(rCustom, { nMod = nTargetDC } );
	end
	
	ActionsManager.performSingleRollAction(draginfo, rActor, "ability", rRoll, rCustom);
end

function modRoll(rSource, rTarget, rRoll)
	if rTarget and rTarget.nOrder then
		return;
	end
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		local bEffects = false;

		local sActionStat = nil;
		local sAbility = string.match(rRoll.sDesc, "%[ABILITY%] (%w+) check");
		if sAbility then
			sAbility = string.lower(sAbility);
		end

		-- GET ACTION MODIFIERS
		local nEffectCount;
		aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"ABIL"}, false, {sAbility});
		if (nEffectCount > 0) then
			bEffects = true;
		end
		
		-- IF EFFECTS HAPPENED, THEN ADD NOTE
		if bEffects then
			local sEffects = "";
			local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
			if sMod ~= "" then
				sEffects = "[EFFECTS " .. sMod .. "]";
			else
				sEffects = "[EFFECTS]";
			end
			table.insert(aAddDesc, sEffects);
		end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	for _,vDie in ipairs(aAddDice) do
		table.insert(rRoll.aDice, "p" .. string.sub(vDie, 2));
	end
	rRoll.nMod = rRoll.nMod + nAddMod;
end

function onRoll(rSource, rTarget, rRoll, rCustom)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	if rCustom and rCustom[1] and rCustom[1].nMod then
		local nTotal = ActionsManager.total(rRoll);
		
		rMessage.text = rMessage.text .. " (vs. TN " .. rCustom[1].nMod .. ")";
		if nTotal >= rCustom[1].nMod then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	end
	
	local nTotal = ActionsManager.total(rRoll);
	Comm.deliverChatMessage(rMessage);
end
