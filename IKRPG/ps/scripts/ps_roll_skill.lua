-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action()	
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
	
	local sSkill = DB.getValue("partysheet.selectedskill", "");
	if sSkill == "" then
		return true;
	end
	
	local nTargetDC = DB.getValue("partysheet.skilldc", 0);
	if nTargetDC == 0 then
		nTargetDC = nil;
	end
	
	local bSecretRoll = window.hiderollresults.getState();
	
	for _,v in pairs(aParty) do
		local nValue = CharManager.getSkillValue(v, sSkill);
		ActionSkill.performRoll(nil, v, sSkill, nValue, nil, nTargetDC, bSecretRoll, true);
	end
	
	return true;
end

function onButtonPress()
	return action();
end			
