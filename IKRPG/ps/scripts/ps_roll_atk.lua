-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local aParty = {};
	for _,v in pairs(window.partylist.getWindows()) do
		local rActor = ActorManager.getActor("pc", v.link.getTargetDatabaseNode());
		if rActor then
			table.insert(aParty, rActor);
		end
	end
	if #aParty == 0 then
		aParty = nil;
	end
	
	local rAction = {};
	rAction.name = "Party Attack";
	rAction.defense = window.attackdef.getStringValue();
	
	local rActionClause = {};
	rActionClause.stat = {};
	rActionClause.mod = window.bonus.getValue();
	rAction.clauses = { rActionClause };
	
	local rRoll = ActionAttack.getRoll(nil, rAction);
	
	local bSecretRoll = window.hiderollresults.getState();
	if bSecretRoll then
		rRoll.sDesc = "[GM] " .. rRoll.sDesc;
	end
	
	local sStackDesc, nStackMod = ModifierStack.getStack(true);
	if sStackDesc ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " (" .. sStackDesc .. ")";
	end
	rRoll.nMod = rRoll.nMod + nStackMod;
	
	local rCustom = nil;
	local sEffectName = StringManager.trim(window.effectlabel.getValue());
	if sEffectName ~= "" then
		local rEffect = {};
		rEffect.sName = window.effectlabel.getValue();
		rEffect.sExpire = window.effectexpiration.getStringValue();
		if window.effectisgmonly.getState() then
			rEffect.nGMOnly = 1;
		else
			rEffect.nGMOnly = 0;
		end
		rEffect.sApply = window.effectapply.getStringValue();
		
		local sEffect = ActionEffect.encodeEffectAsText(rEffect);
		local nSaveMod = window.effectsavemod.getValue();
		
		rCustom = {};
		local rCustomTable = {};
		rCustomTable.sClass = "effect";
		rCustomTable.sDesc = sEffect;
		rCustomTable.nMod = nSaveMod;
		rCustom = { rCustomTable };
	end

	for _,v in pairs(aParty) do
		ActionsManager.handleActionNonDrag(nil, "attack", { rRoll }, rCustom, { { v } });
	end
	return true;
end

function onButtonPress()
	return action();
end			

