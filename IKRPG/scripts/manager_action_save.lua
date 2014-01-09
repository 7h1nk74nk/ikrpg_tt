-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerActionIcon("save", "action_roll");
	ActionsManager.registerModHandler("save", modSave);
	ActionsManager.registerModHandler("autosave", modSave);
	ActionsManager.registerResultHandler("save", onSave);
	ActionsManager.registerResultHandler("autosave", onSave);
end

function performRoll(draginfo, rActor, bGMOnly, bAddName, nodeEffect)
	-- Build the basic roll
	local rRoll = {};
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManager.getSave(rActor);
	if nodeEffect then
		rRoll.nMod = rRoll.nMod + DB.getValue(nodeEffect, "effectsavemod", 0);
	end
	
	rRoll.sDesc = "[SAVE]";
	if bAddName then
		rRoll.sDesc = "[ADDNAME] " .. rRoll.sDesc;
	end
	if bGMOnly then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	
	local rCustom = nil;
	if nodeEffect then
		local rCustomEffect = {};
		rCustomEffect.sRecord = nodeEffect.getNodeName();
		rCustom = { rCustomEffect };
	end
	
	-- Make the roll
	ActionsManager.performSingleRollAction(draginfo, rActor, "save", rRoll, rCustom);
end

function performAutoRoll(rActor, bGMOnly, bDeathSave, nodeEffect)
	-- Build the basic roll
	local rRoll = {};
	rRoll.aDice = { "d20" };
	rRoll.nMod = ActorManager.getSave(rActor);
	if nodeEffect then
		rRoll.nMod = rRoll.nMod + DB.getValue(nodeEffect, "effectsavemod", 0);
	end
	
	rRoll.sDesc = "[SAVE]";
	if bGMOnly then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	local rCustom = nil;
	if bDeathSave then
		rRoll.sDesc = rRoll.sDesc .. " [DEATH]";
	elseif nodeEffect then
		local rCustomEffect = {};
		rCustomEffect.sRecord = nodeEffect.getNodeName();
		rCustom = { rCustomEffect };
	end
	
	-- Make the roll
	ActionsManager.performSingleRollAction(nil, rActor, "autosave", rRoll, rCustom);
end

function modSave(rSource, rTarget, rRoll, rCustom)
	-- Tell the actions handle to skip the modifier stack for auto-saves
	local bReturn = nil;
	if rRoll.sType == "autosave" then
		bReturn = true;
	end
	
	if rTarget and rTarget.nOrder then
		return bReturn;
	end
	
	local bDeathSave = false;
	if rRoll.sType == "save" then
		-- If this is not an effect save, then check for shift key for death save
		if not rCustom or #rCustom == 0 then
			bDeathSave = Input.isShiftPressed();
			if bDeathSave then
				rRoll.sDesc = rRoll.sDesc .. " [DEATH]";
			end
		end
	elseif rRoll.sType == "autosave" then
		bDeathSave = string.match(rRoll.sDesc, "%[DEATH%]");
	end

	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	if rSource then
		-- Build effect filter
		local aSaveFilter = {};
		if bDeathSave then
			table.insert(aSaveFilter, "death");
		end
		
		-- Get effect modifiers
		local aAddDice, nAddMod, nEffectCount = EffectsManager.getEffectsBonus(rSource, {"SAVE"}, false, aSaveFilter);
		if nEffectCount > 0 then
			for _, vDie in ipairs(aAddDice) do
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
	
	return bReturn;
end

function onSave(rSource, rTarget, rRoll, rCustom)
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	local nTotal = ActionsManager.total(rRoll);

	-- Handle death save results
	if string.match(rRoll.sDesc, "%[DEATH%]") then
		if nTotal >= 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
			if rSource then
				local nMaxHealSurge = DB.getValue(rSource.nodeCreature, "hp.surgesmax", 0);
				local nUsedHealSurge = DB.getValue(rSource.nodeCreature, "hp.surgesused", 0);
				if nUsedHealSurge >= nMaxHealSurge then
					rMessage.text = rMessage.text .. " [NO HEALING SURGES REMAINING]";
				else
					local sHeal = "[HEAL] Death Save Critical Success [HSV 1] [COST 1]";
					if string.match(rRoll.sDesc, "^%[GM%]") or string.match(rRoll.sDesc, "^%[TOWER%]") then
						sHeal = "[GM] " .. sHeal;
					end
					ActionDamage.applyDamage(nil, rSource, 0, sHeal);
				end
			end
		elseif nTotal >= 10 then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
			
			-- ADD FAILED DEATH SAVE
			if rSource then
				if rSource.sType == "pc" and rSource.nodeCreature then
					local nFailedSaves = DB.getValue(rSource.nodeCreature, "hp.faileddeathsaves", 0);
					nFailedSaves = nFailedSaves + 1;
					if nFailedSaves >= 3 then
						nFailedSaves = 3;
						rMessage.text = rMessage.text .. " [DEAD]";
					else
						rMessage.text = rMessage.text .. " [DYING (" .. nFailedSaves .. ")]";
					end
					DB.setValue(rSource.nodeCreature, "hp.faileddeathsaves", "number", nFailedSaves);
				end
			end
		end
	
	-- Otherwise, it's a standard save
	else
		rMessage.text = string.gsub(rMessage.text, " %[SUCCESS%]", "");
		rMessage.text = string.gsub(rMessage.text, " %[FAILURE%]", "");
		rMessage.text = string.gsub(rMessage.text, " %[MULTIPLE SAVE EFFECTS%]", "");
		
		if nTotal >= 10 then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
		
		-- Determine target effect, if we can
		local nodeTargetEffect = nil;
		if rCustom and rCustom[1] and rCustom[1].sRecord and rCustom[1].sRecord ~= "" then
			nodeTargetEffect = DB.findNode(rCustom[1].sRecord);
		elseif rSource and rSource.nodeCT then
			local bFound = false;
			for kEffect, nodeEffect in pairs(DB.getChildren(rSource.nodeCT, "effects")) do
				if DB.getValue(nodeEffect, "expiration", "") == "save" then
					if bFound then
						rMessage.text = rMessage.text .. " [MULTIPLE SAVE EFFECTS]";
						nodeTargetEffect = nil;
						break;
					else
						bFound = true;
						nodeTargetEffect = nodeEffect;
					end
				end
			end
		end
		
		-- If target effect found, then apply result to effect
		if nodeTargetEffect then
			if nTotal >= 10 then
				EffectsManager.notifyExpire(nodeTargetEffect, 0);
				rMessage.text = rMessage.text .. "*";
			else
				EffectsManager.notifyFailedSave(nodeTargetEffect);
			end
		end
	end

	Comm.deliverChatMessage(rMessage);
end
