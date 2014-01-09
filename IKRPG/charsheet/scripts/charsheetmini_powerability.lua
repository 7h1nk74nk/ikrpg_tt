-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function isWeaponPower()
	local sKeywords = string.lower(DB.getValue(getDatabaseNode(), "...keywords", ""));
	if sKeywords:match("weapon") then
		return true;
	end
	return false;
end

function highlight(bState)
	if bState then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function onFilter()
	local abilitytype = type.getStringValue();
	local abilitynode = getDatabaseNode();

	-- Determine some details about the ability
	local isAttack = false;
	local isHeal = false;
	local isEffect = false;
	if abilitytype == "attack" then
		isAttack = true;
	elseif abilitytype == "heal" then
		isHeal = true;
	elseif abilitytype == "effect" then
		isEffect = true;
	end
	local isWeapon = isWeaponPower();
	
	-- Handle the focus elements of this attack (weapon / implement)
	local showfocus = (focus.getValue() ~= 0);

	-- Handle the attack elements
	local showattack = false;
	showattack = (DB.getValue(abilitynode, "attackstat", "") ~= "") or showattack;
	showattack = (DB.getValue(abilitynode, "attackstatmodifier", 0) ~= 0) or showattack;
	showattack = (DB.getValue(abilitynode, "attackdef", "") ~= "") or showattack;

	-- Handle the damage elements
	local showdamage = false;
	if isWeapon then
		showdamage = (DB.getValue(abilitynode, "damageweaponmult", 0) > 0) or showdamage;
	end
	local tempdice = DB.getValue(abilitynode, "damagebasicdice", {});
	showdamage = (#tempdice > 0) or showdamage;
	showdamage = (DB.getValue(abilitynode, "damagestat", "") ~= "") or showdamage;
	showdamage = (DB.getValue(abilitynode, "damagestat2", "") ~= "") or showdamage;
	showdamage = (DB.getValue(abilitynode, "damagestatmodifier", 0) ~= 0) or showdamage;

	-- Handle the heal elements
	local showheal = false;
	showheal = (DB.getValue(abilitynode, "hsvmult", 0) > 0) or showheal;
	tempdice = DB.getValue(abilitynode, "healdice", {});
	showheal = (#tempdice > 0) or showheal;
	showheal = (DB.getValue(abilitynode, "healstat", "") ~= "") or showheal;
	showheal = (DB.getValue(abilitynode, "healstat2", "") ~= "") or showheal;
	showheal = (DB.getValue(abilitynode, "healmod", 0) ~= 0) or showheal;
	showheal = (DB.getValue(abilitynode, "healcost", 0) ~= 0) or showheal;

	-- Handle the effect elements
	local showeffect = false;
	showeffect = (DB.getValue(abilitynode, "label", "") ~= "") or showeffect;

	---- ATTACK ----
	focuslabel.setVisible(isAttack and showfocus);
	focus.setVisible(isAttack and showfocus);
	if isWeapon then
		focuslabel.setValue("Wpn:");
	else
		focuslabel.setValue("Imp:");
	end
	attacklabel.setVisible(isAttack and showattack);
	attackicon.setVisible(isAttack and showattack);
	damagelabel.setVisible(isAttack and showdamage);
	damageicon.setVisible(isAttack and showdamage);

	---- HEAL ----
	heallabel.setVisible(isHeal and showheal);
	healicon.setVisible(isHeal and showheal);
	
	---- EFFECT ----
	effectview.setVisible(isEffect and showeffect);
	
	if abilitytype == "attack" then
		-- Return visibility depending on if any fields are visible
		return (showfocus or showattack or showdamage);
	
	elseif abilitytype == "heal" then
		return showheal;
		
	elseif abilitytype == "effect" then
		return showeffect;
	end
	
	-- If no type chosen yet, then always hide
	return false;
end

