-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Ability", "deletepointer", 3);
	registerMenuItem("Confirm Remove", "delete", 3, 3);
	
	updateDisplay();
	
	windowlist.getOrder(getDatabaseNode());
end
			
function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		getDatabaseNode().delete();
	end
end

function isWeaponPower()
	local sKeywords = string.lower(DB.getValue(getDatabaseNode(), "...keywords", ""));
	if sKeywords:match("weapon") then
		return true;
	end
	return false;
end

function isDamageVisible()
	return activatedmgdetail.getValue() and (type.getStringValue() == "attack");
end

function isHealVisible()
	return activatehealdetail.getValue() and (type.getStringValue() == "heal");
end

function updateDisplay()
	-- Determine what type of ability we are working with
	local abilitytype = type.getStringValue();
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
	
	---- ATTACK ----
	
	-- Update focus display
	focuslabel.setVisible(isAttack);
	focus.setVisible(isAttack);
	if isWeapon then
		focuslabel.setValue("Wpn:");
	else
		focuslabel.setValue("Imp:");
	end
	
	-- Update attack display
	attacklabel.setVisible(isAttack);
	attackview.setVisible(isAttack);
	activateatkdetail.setVisible(isAttack);
	onAttackChanged();
	local atkval = activateatkdetail.getValue() and isAttack;
	attackdetaillabel.setVisible(atkval);
	attackstat.setVisible(atkval);
	attackpluslabel.setVisible(atkval);
	attackstatmodifier.setVisible(atkval);
	attackvslabel.setVisible(atkval);
	attackdef.setVisible(atkval);

	-- Update damage display
	damagelabel.setVisible(isAttack);
	damageview.setVisible(isAttack);
	onDamageChanged();
	local dmgval = activatedmgdetail.getValue() and isAttack;
	damagedetaillabel.setVisible(dmgval);
	activatedmgdetail.setVisible(isAttack);
	if isWeapon then
		damageweaponmult.setVisible(dmgval);
		damageweaponmultlabel.setVisible(dmgval);
		damagepluslabel1.setVisible(dmgval);
	else
		damageweaponmult.setVisible(false);
		damageweaponmultlabel.setVisible(false);
		damagepluslabel1.setVisible(false);
	end
	damagebasicdice.setVisibility(dmgval);
	damagepluslabel2.setVisible(dmgval);
	damagestatmult.setVisible(dmgval);
	damagestat.setVisible(dmgval);
	damagepluslabel3.setVisible(dmgval);
	damagestatmult2.setVisible(dmgval);
	damagestat2.setVisible(dmgval);
	damagepluslabel4.setVisible(dmgval);
	damagestatmodifier.setVisible(dmgval);
	damagetypelabel.setVisible(dmgval);
	damagetype.setVisible(dmgval);

	---- HEAL ----
	healtypelabel.setVisible(isHeal);
	healtype.setVisible(isHeal);
	healtargeting.setVisible(isHeal);
	healview.setVisible(isHeal);
	activatehealdetail.setVisible(isHeal);
	healcostlabel.setVisible(isHeal);
	healcost.setVisible(isHeal);
	healcostlabel2.setVisible(isHeal);
	onHealChanged();
	local healval = activatehealdetail.getValue() and isHeal;
	healdetaillabel.setVisible(healval);
	hsvmult.setVisible(healval);
	hsvmultlabel.setVisible(healval);
	healpluslabel1.setVisible(healval);
	healdice.setVisibility(healval);
	healpluslabel2.setVisible(healval);
	healstatmult.setVisible(healval);
	healstat.setVisible(healval);
	healpluslabel3.setVisible(healval);
	healstatmult2.setVisible(healval);
	healstat2.setVisible(healval);
	healpluslabel4.setVisible(healval);
	healmod.setVisible(healval);
	
	---- EFFECT ----
	targeting.setVisible(isEffect);
	apply.setVisible(isEffect);
	label.setVisible(isEffect);
	expiration.setVisible(isEffect);
	if expiration.getStringValue() == "save" then
		savemod.setVisible(isEffect);
	else
		savemod.setVisible(false);
	end

	-- Update spacer display;
	spacer.setVisible((atkval or dmgval or healval) and isAttack);
end

function onAttackChanged()
	-- Build the attack display string
	local s = "";
	
	if attackstat.getStringValue() ~= "" then
		s = s .. attackstat.getValue();
	end
	if attackstatmodifier.getValue() ~= 0 then
		s = s .. string.format("%+d", attackstatmodifier.getValue());
	end
	local sAttackDef = attackdef.getStringValue();
	if s ~= "" or sAttackDef ~= "" then
		s = s .. " vs ";
	end
	if sAttackDef ~= "" then
		s = s .. attackdef.getValue();
	end
	
	attackview.setValue(s);
end

function onDamageChanged()
	-- Build the damage display string
	local strtable = {};
	if isWeaponPower() and damageweaponmult.getValue() ~= 0 then
		table.insert(strtable, "" .. damageweaponmult.getValue() .. "[W]");
	end
	local dice = damagebasicdice.getDatabaseNode().getValue();
	if dice and #dice > 0 then
		table.insert(strtable, StringManager.convertDiceToString(dice));
	end
	if damagestat.getStringValue() ~= "" then
		local statmult = damagestatmult.getStringValue();
		if statmult == "double" then
			table.insert(strtable, "(2x" .. damagestat.getValue() .. ")");
		elseif statmult == "half" then
			table.insert(strtable, "(1/2x" .. damagestat.getValue() .. ")");
		else
			table.insert(strtable, damagestat.getValue());
		end
	end
	if damagestat2.getStringValue() ~= "" then
		local statmult = damagestatmult2.getStringValue();
		if statmult == "double" then
			table.insert(strtable, "(2x" .. damagestat2.getValue() .. ")");
		elseif statmult == "half" then
			table.insert(strtable, "(1/2x" .. damagestat2.getValue() .. ")");
		else
			table.insert(strtable, damagestat2.getValue());
		end
	end
	if damagestatmodifier.getValue() ~= 0 then
		table.insert(strtable, "" .. damagestatmodifier.getValue());
	end
	
	-- Concatenate the damage clauses together
	local s = table.concat(strtable, "+");
	
	-- Add the damage type
	if s ~= "" and damagetype.getValue() ~= "" then
		s = s .. " " .. damagetype.getValue();
	end
	
	-- Set the attack display to the new text
	damageview.setValue(s);
end

function onHealChanged()
	-- Build the damage display string
	local strtable = {};
	if hsvmult.getValue() ~= 0 then
		table.insert(strtable, "" .. hsvmult.getValue() .. "[HSV]");
	end
	local dice = healdice.getDatabaseNode().getValue();
	if dice and #dice > 0 then
		table.insert(strtable, StringManager.convertDiceToString(dice));
	end
	if healstat.getStringValue() ~= "" then
		local statmult = healstatmult.getStringValue();
		if statmult == "double" then
			table.insert(strtable, "(2x" .. healstat.getValue() .. ")");
		elseif statmult == "half" then
			table.insert(strtable, "(1/2x" .. healstat.getValue() .. ")");
		else
			table.insert(strtable, healstat.getValue());
		end
	end
	if healstat2.getStringValue() ~= "" then
		local statmult = healstatmult2.getStringValue();
		if statmult == "double" then
			table.insert(strtable, "(2x" .. healstat2.getValue() .. ")");
		elseif statmult == "half" then
			table.insert(strtable, "(1/2x" .. healstat2.getValue() .. ")");
		else
			table.insert(strtable, healstat2.getValue());
		end
	end
	if healmod.getValue() ~= 0 then
		table.insert(strtable, "" .. healmod.getValue());
	end
	
	-- Concatenate the damage clauses together
	local s = table.concat(strtable, "+");
	if s == "" then
		s = "0";
	end
	
	-- Set the attack display to the new text
	healview.setValue(s);
end

