-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	update();
end

function updateControl(sControl, bLock, vHideOnValue)
	local bLocalShow = true;
	
	if self[sControl] then
		if bLock then
			self[sControl].setReadOnly(true);
			
			local val = self[sControl].getValue();
			if val == "" or val == vHideOnValue then
				bLocalShow = false;
			end
		else
			self[sControl].setReadOnly(false);
		end
		self[sControl].setVisible(bLocalShow);
	else
		bLocalShow = false;
	end

	if self[sControl .. "_label"] then
		self[sControl .. "_label"].setVisible(bLocalShow);
	end
	
	return bLocalShow;
end

function update()
	local bLock = parentcontrol.window.getAccessState();
	
	-- GENERAL
	updateControl("hp", bLock);
	updateControl("init", bLock);
	updateControl("ac", bLock, 0);
	updateControl("fortitude", bLock, 0);
	updateControl("reflex", bLock, 0);
	updateControl("will", bLock, 0);
	updateControl("specialdefenses", bLock);
	updateControl("speed", bLock);

	-- NPC / TEMPLATE
	updateControl("perceptionval", bLock);
	updateControl("senses", bLock);
	updateControl("save", bLock, 0);
	updateControl("ap", bLock, 0);
	if save and ap then
		if bLock and not save.isVisible() and not ap.isVisible() then
			columnanchor.setAnchor("top", "specialdefenses", "bottom");
		else
			columnanchor.setAnchor("top", "save_label", "bottom");
		end
	end

	-- NPC SPECIFIC
	updateControl("skills", bLock);
	if skills then
		if bLock and not skills.isVisible() then
			shadedrow.setAnchoredHeight(33);
			strength_label.setAnchor("top", "shadedrow", "top", "absolute", 1);
			constitution_label.setAnchor("top", "shadedrow", "top", "absolute", 16);
		else
			shadedrow.setAnchoredHeight(48);
			strength_label.setAnchor("top", "shadedrow", "top", "absolute", 16);
			constitution_label.setAnchor("top", "shadedrow", "top", "absolute", 31);
		end
	end
	updateControl("strength", bLock);
	updateControl("constitution", bLock);
	updateControl("dexterity", bLock);
	updateControl("intelligence", bLock);
	updateControl("wisdom", bLock);
	updateControl("charisma", bLock);

	updateControl("alignment", bLock);
	updateControl("languages", bLock);
	updateControl("equipment", bLock);
	
	-- TEMPLATE SPECIFIC
	updateControl("weaponproficiency", bLock);
	updateControl("armorproficiency", bLock);
	updateControl("trainedskills", bLock);
	updateControl("classfeatures", bLock);
	updateControl("implement", bLock);
	
	-- POWERS
	if list_vpowers then
		list_vpowers.setReadOnly(bLock);
		list_vpowers.update();
	end
	if list_powers then
		list_powers.setReadOnly(bLock);
		list_powers.update();
		powers_header.setVisible(list_powers.isVisible());
		powers_label.setVisible(list_powers.isVisible());
	end
	
	-- TRAP SPECIFIC
	updateControl("flavor", bLock);
	updateControl("trapdesc", bLock);
	updateControl("detect", bLock);
	if list_skills then
		list_skills.setReadOnly(bLock);
		list_skills.update();
	end
	if list_countermeasures then
		list_countermeasures.setReadOnly(bLock);
		list_countermeasures.update();
		countermeasures_label.setVisible(list_countermeasures.isVisible());
		countermeasures_header.setVisible(list_countermeasures.isVisible());
	end
	
	-- VEHICLE SPECIFIC
	updateControl("cost", bLock);
	updateControl("space", bLock);
end
