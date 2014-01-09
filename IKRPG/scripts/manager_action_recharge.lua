-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("recharge", modRecharge);
	ActionsManager.registerResultHandler("recharge", onRecharge);
end

function performRoll(draginfo, rActor, sRecharge, nRecharge, bGMOnly, nodeEffect)
	-- Build the basic roll
	local rRoll = {};
	rRoll.aDice = { "d6" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[RECHARGE " .. nRecharge .. "+] " .. sRecharge;
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
	ActionsManager.performSingleRollAction(draginfo, rActor, "recharge", rRoll, rCustom);
end

function modRecharge(rSource, rTarget, rRoll)
	-- Tell action manager to skip modifier stack
	return true;
end

function onRecharge(rSource, rTarget, rRoll, rCustom)
	-- Validate
	if not User.isHost() then
		ChatManager.SystemMessage("[ERROR] Received recharge roll on client");
		return;
	end
	
	-- Create basic message
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Determine target effect
	local nodeTargetEffect = nil;
	if rCustom and rCustom[1] and rCustom[1].sRecord and rCustom[1].sRecord ~= "" then
		nodeTargetEffect = DB.findNode(rCustom[1].sRecord);
	end
	
	-- If target effect found, then check for recharge
	if nodeTargetEffect then
		-- Check the effect components
		local sEffectName = DB.getValue(nodeTargetEffect, "label", "");
		local aEffectList = EffectsManager.parseEffect(sEffectName);
		local nRecharge = nil;
		local sRecharge = "";
		for i = 1, #aEffectList do
			if aEffectList[i].type == "RCHG" then
				nRecharge = aEffectList[i].mod;
				sRecharge = table.concat(aEffectList[i].remainder, " ");
				break;
			end
		end
		
		-- Check for successful recharge
		local nTotal = ActionsManager.total(rRoll);
		if nRecharge and nTotal >= nRecharge then
			-- Add notification
			rMessage.text = rMessage.text .. " [RECHARGED]";
			
			-- Delete effect
			local nodeEffectsList = nodeTargetEffect.getParent();
			nodeTargetEffect.delete();
			if nodeEffectsList.getChildCount() == 0 then
				nodeEffectsList.createChild();
			end

			-- Remove the [USED] marker from attack line
			for _, nodeAttack in pairs(DB.getChildren(nodeEffectsList, "..attacks")) do
				local sAttack = DB.getValue(nodeAttack, "value", "");
				local rPower = CTManager.parseCTAttackLine(sAttack);
				if rPower and rPower.sUsage and rPower.name == sRecharge then
					local sNew = string.sub(sAttack, 1, rPower.nUsageStart - 2) .. string.sub(sAttack, rPower.nUsageEnd + 1);
					DB.setValue(nodeAttack, "value", "string", sNew);
				end
			end
		end
	end

	-- Deliver message
	Comm.deliverChatMessage(rMessage);
end
