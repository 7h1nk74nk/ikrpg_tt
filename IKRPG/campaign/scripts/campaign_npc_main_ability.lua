-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();
	updateMod();
end

function onValueChanged()
	updateMod();
end

function updateMod()
	local sLevelRole = string.lower(DB.getValue(window.getDatabaseNode(), "levelrole", ""));
	local nLevel = tonumber(sLevelRole:match("level%s(%d+)")) or 0;

	local nLevelMod = math.floor(nLevel / 2);
	local nAbilityMod = math.floor((getValue() - 10) / 2);
	
	local nMod = nLevelMod + nAbilityMod;
	if nMod == 0 then
		window[mod[1]].setValue("(+0)");
	else
		window[mod[1]].setValue(string.format("(%+d)", nMod));
	end
end

function action(draginfo)
	local rActor = ActorManager.getActor("npc", window.getDatabaseNode());
	ActionAbility.performRoll(draginfo, rActor, self.target[1]);
	
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
	
function onDoubleClick(x, y)
	return action();
end
