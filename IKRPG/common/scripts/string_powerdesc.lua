-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bParsed = false;
local aAbilities = {};

local bDragging = nil;
local hoverAbility = nil;
local clickAbility = nil;

function onValueChanged()
	bParsed = false;
end

function onEnter()
	if Input.isShiftPressed() then
		if window.windowlist and window.windowlist.onEnter then
			window.windowlist.onEnter();
		end
		return true;
	end
	
	return false;
end

function parseComponents()
	local sCreatureName = "";
	if self.getCreatureName then
		sCreatureName = self.getCreatureName();
	end
	
	local sPower = getValue();
	aAbilities = PowersManager.parsePowerDescription(sPower, sCreatureName);
	bParsed = true;
end

-- Reset selection when the cursor leaves the control
function onHover(bOnControl)
	if bDragging or bOnControl then
		return;
	end

	hoverAbility = nil;
	setSelectionPosition(0);
end

-- Hilight attack or damage hovered on
function onHoverUpdate(x, y)
	if bDragging then
		return;
	end

	if not bParsed then
		parseComponents();
	end
	local nMouseIndex = getIndexAt(x, y);

	for i = 1, #aAbilities do
		if aAbilities[i].startpos <= nMouseIndex and aAbilities[i].endpos > nMouseIndex then
			setCursorPosition(aAbilities[i].startpos);
			setSelectionPosition(aAbilities[i].endpos);

			hoverAbility = i;			
			setHoverCursor("hand");
			return;
		end
	end

	hoverAbility = nil;
	setHoverCursor("arrow");
end

function getRollStructures(rOriginalAbility)
	local rActor = nil;
	if self.getCreatureType and self.getCreatureNode then
		rActor = ActorManager.getActor(self.getCreatureType(), self.getCreatureNode());
	end
	
	local node = window.getDatabaseNode();
	if not node then
		node = window.windowlist.window.getDatabaseNode();
	end
	
	local rAction = rOriginalAbility;
	rAction.name = DB.getValue(node, "name", "");
	rAction.range = string.upper(DB.getValue(node, "powertype", ""));
	if rAction.range == "" then
		local listRangeWords = StringManager.parseWords(string.lower(DB.getValue(node, "range", "")));
		if StringManager.isWord(listRangeWords[1], "melee") then
			rAction.range = "M";
		elseif StringManager.isWord(listRangeWords[1], "ranged") then
			rAction.range = "R";
		elseif StringManager.isWord(listRangeWords[1], "close") then
			rAction.range = "C";
		elseif StringManager.isWord(listRangeWords[1], "area") then
			rAction.range = "A";
		else
			rAction.range = "";
		end
	end
	
	local rFocus = nil;
	if rAction.type == "attack" or rAction.type == "damage" then
		local keywords = string.lower(DB.getValue(node, "keywords", ""));
		if string.match(keywords, "weapon") and self.getWeaponRecord then
			rFocus = self.getWeaponRecord(rAction.type);
		end
		if string.match(keywords, "implement") and self.getImplementRecord then
			rFocus = self.getImplementRecord(rAction.type);
		end
	end
	
	return rActor, rAction, rFocus;
end

function getEffectStructures(rAction)
	local rActor = nil;
	if self.getCreatureType and self.getCreatureNode then
		rActor = ActorManager.getActor(self.getCreatureType(), self.getCreatureNode());
	end

	local rEffect = {};
	rEffect.sName = EffectsManager.evalEffect(rActor, rAction.name);
	rEffect.sExpire = rAction.expire;
	rEffect.nSaveMod = rAction.mod;
	rEffect.sApply = rAction.sApply;
	rEffect.sTargeting = rAction.sTargeting;
	
	if rActor and rActor.nodeCT then
		rEffect.sSource = rActor.sCTNode;
		rEffect.nInit = DB.getValue(rActor.nodeCT, "initresult", "");
	else
		rEffect.sSource = "";
		rEffect.nInit = 0;
	end
	
	return rActor, rEffect;
end

function action(draginfo, rAction)
	if rAction.type == "attack" then
		local rActor, rTempAbility, rFocus = getRollStructures(rAction);
		ActionAttack.performRoll(draginfo, rActor, rTempAbility, rFocus);
		return true;
	elseif rAction.type == "damage" then
		local rActor, rTempAbility, rFocus = getRollStructures(rAction);
		ActionDamage.performRoll(draginfo, rActor, rTempAbility, rFocus);
		return true;
	elseif rAction.type == "heal" then
		local rActor, rTempAbility, rFocus = getRollStructures(rAction);
		ActionHeal.performRoll(draginfo, rActor, rTempAbility, rFocus);
		return true;
	elseif rAction.type == "effect" then
		local rActor, rEffect = getEffectStructures(rAction);
		ActionEffect.performRoll(draginfo, rActor, rEffect);
		return true;
	end
end

-- Suppress default processing to support dragging
function onClickDown(button, x, y)
	clickAbility = hoverAbility;
	return true;
end

-- On mouse click, set focus, set cursor position and clear selection
function onClickRelease(button, x, y)
	setFocus();
	
	local n = getIndexAt(x, y);
	setSelectionPosition(n);
	setCursorPosition(n);
	
	return true;
end

function onDoubleClick(x, y)
	if hoverAbility then
		action(nil, aAbilities[hoverAbility]);
		return true;
	end
end

function onDragStart(button, x, y, draginfo)
	return onDrag(button, x, y, draginfo);
end

function onDrag(button, x, y, draginfo)
	if bDragging then
		return true;
	end

	if clickAbility then
		action(draginfo, aAbilities[clickAbility]);
		clickAbility = nil;
		bDragging = true;
		return true;
	end
	
	return true;
end

function onDragEnd(dragdata)
	setCursorPosition(0);
	bDragging = false;
end
