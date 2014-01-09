-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

targetingon = false;
activeon = false;
defensiveon = false;
spacingon = false;
effectson = false;

function onInit()
	onTypeChanged();
	
	-- Set the displays to what should be shown
	setTargetingVisible(false);
	setActiveVisible(false);
	setDefensiveVisible(false);
	setSpacingVisible(false);
	setEffectsVisible(false);

	-- Acquire token reference, if any
	linkToken();
	
	-- Set up the PC links
	if type.getValue() == "pc" then
		linkPCFields();
	end
	
	-- Update the displays
	onFactionChanged();
	onWoundsChanged();
	
	-- Register the deletion menu item for the host
	registerMenuItem("Delete Item", "delete", 6);
	registerMenuItem("Confirm Delete", "delete", 6, 7);

	-- Track the effects list
	local nodeEffects = effects.getDatabaseNode();
	if nodeEffects then
		nodeEffects.onChildUpdate = onEffectsChanged;
		nodeEffects.onChildAdded = onEffectsChanged;
		onEffectsChanged();
	end
	
	-- Track the targets list
	local nodeTargets = targets.getDatabaseNode();
	if nodeTargets then
		nodeTargets.onChildUpdate = onTargetsChanged;
		nodeTargets.onChildAdded = onTargetsChanged;
		onTargetsChanged();
	end
end

function updateDisplay()
	local sFaction = friendfoe.getStringValue();

	if type.getValue() ~= "pc" then
		name.setLine(true, 0);
	end

	if DB.getValue(getDatabaseNode(), "active", 0) == 1 then
		name.setFont("ct_active");
		
		active_spacer_top.setVisible(true);
		active_spacer_bottom.setVisible(true);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend_active");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral_active");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe_active");
		else
			setFrame("ctentrybox_active");
		end
	else
		name.setFont("ct_name");
		
		active_spacer_top.setVisible(false);
		active_spacer_bottom.setVisible(false);
		
		if sFaction == "friend" then
			setFrame("ctentrybox_friend");
		elseif sFaction == "neutral" then
			setFrame("ctentrybox_neutral");
		elseif sFaction == "foe" then
			setFrame("ctentrybox_foe");
		else
			setFrame("ctentrybox");
		end
	end
end

function linkToken()
	local imageinstance = token.populateFromImageNode(tokenrefnode.getValue(), tokenrefid.getValue());
	if imageinstance then
		CTManager.linkToken(getDatabaseNode(), imageinstance);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
end

function delete()
	local node = getDatabaseNode();
	if not node then
		close();
		return;
	end
	
	-- Remember node name
	local sNode = node.getNodeName();
	
	-- Clear any effects and wounds first, so that saves aren't triggered when initiative advanced
	effects.reset(false);
	wounds.setValue(0);
	
	-- Move to the next actor, if this CT entry is active
	if DB.getValue(node, "active", 0) == 1 then
		CTManager.nextActor();
	end

	-- If this is an NPC with a token on the map, then remove the token also
	if type.getValue() ~= "pc" then
		token.deleteReference();
	end

	-- Delete the database node and close the window
	node.delete();

	-- Update list information (global subsection toggles, targeting)
	windowlist.onVisibilityToggle();
	windowlist.onEntrySectionToggle();
	windowlist.deleteTarget(sNode);
	TargetingManager.rebuildClientTargeting();
end

function onTypeChanged()
	-- If a PC, then set up the links to the char sheet
	local sType = type.getValue();
	if sType == "pc" then
		linkPCFields();
	end
end

function onWoundsChanged()
	local sColor, nPercentWounded, sStatus = ActorManager.getWoundColor("ct", getDatabaseNode());
	wounds.setColor(sColor);
	status.setValue(sStatus);

	if type.getValue() ~= "pc" then
		qdelete.setVisible((nPercentWounded > 1));
	end
end

function onSurgesChanged()
	-- Update the healing surges remaining field when healing surges max or healing surges used changes
	if type.getValue() == "pc" then
		healsurgeremaining.setValue(healsurgesmax.getValue() - healsurgesused.getValue());
	end
end

function onAPChanged()
	-- Update the action points remaining field when action points max or action points used changes
	if type.getValue() == "pc" then
		actionpoints.setValue(apmax.getValue() - apused.getValue());
	end
end

function onFactionChanged()
	-- Update the entry frame
	updateDisplay();

	-- If not a friend, then show visibility toggle
	if friendfoe.getStringValue() == "friend" then
		show_npc.setVisible(false);
	else
		show_npc.setVisible(true);
	end
end

function onVisibilityChanged()
	TokenManager.updateVisibility(getDatabaseNode());
	windowlist.onVisibilityToggle();
end

function onEffectsChanged()
	-- SET THE EFFECTS CONTROL STRING
	local affectedby = EffectsManager.getEffectsString(getDatabaseNode());
	effects_str.setValue(affectedby);
	
	-- UPDATE VISIBILITY
	if affectedby == "" or effectson then
		effects_label.setVisible(false);
		effects_str.setVisible(false);
	else
		effects_label.setVisible(true);
		effects_str.setVisible(true);
	end
	setSpacerState();
end

function onTargetsChanged()
	-- VALIDATE (SINCE THIS FUNCTION CAN BE CALLED BEFORE FULLY INSTANTIATED)
	if not targets_str then
		return;
	end
	
	-- GET TARGET NAMES
	local aTargetNames = {};
	for keyTarget, winTarget in pairs(targets.getWindows()) do
		local sTargetName = DB.getValue(DB.findNode(winTarget.noderef.getValue()), "name", "");
		if sTargetName == "" then
			sTargetName = "<Target>";
		end
		table.insert(aTargetNames, sTargetName);
	end

	-- SET THE TARGETS CONTROL STRING
	targets_str.setValue(table.concat(aTargetNames, ", "));
	
	-- UPDATE VISIBILITY
	if #aTargetNames == 0 or targetingon then
		targets_label.setVisible(false);
		targets_str.setVisible(false);
	else
		targets_label.setVisible(true);
		targets_str.setVisible(true);
	end
	setSpacerState();
end

function setSpacerState()
	if effects_label.isVisible() then
		if targets_label.isVisible() then
			spacer2.setAnchoredHeight(2);
		else
			spacer2.setAnchoredHeight(6);
		end
	else
		spacer2.setAnchoredHeight(0);
	end
end

function linkPCFields()
	local nodeChar = link.getTargetDatabaseNode();
	if nodeChar then
		name.setLink(nodeChar.createChild("name", "string"), true);

		hp.setLink(nodeChar.createChild("hp.total", "number"));
		hptemp.setLink(nodeChar.createChild("hp.temporary", "number"));
		wounds.setLink(nodeChar.createChild("hp.wounds", "number"));

		healsurgesused.setLink(nodeChar.createChild("hp.surgesused", "number"));
		healsurgesmax.setLink(nodeChar.createChild("hp.surgesmax", "number"));
		healsurgeval.setLink(nodeChar.createChild("hp.surge", "number"));

		healsurgeremaining.addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -5);
		healsurgeremaining.setReadOnly(true);

		ac.setLink(nodeChar.createChild("defenses.ac.total", "number"), true);
		fortitude.setLink(nodeChar.createChild("defenses.fortitude.total", "number"), true);
		reflex.setLink(nodeChar.createChild("defenses.reflex.total", "number"), true);
		will.setLink(nodeChar.createChild("defenses.will.total", "number"), true);
		save.setLink(nodeChar.createChild("defenses.save.total", "number"), true);
		specialdef.setLink(nodeChar.createChild("defenses.special", "string"), true);

		speed.setLink(nodeChar.createChild("speed.final", "number"), true);
		init.setLink(nodeChar.createChild("initiative.total", "number"), true);
		
		for _,nodePower in pairs(DB.getChildren(nodeChar, "powers")) do
			if DB.getValue(nodePower, "name", "") == "Action Point" then
				apmax.setLink(nodePower.createChild("prepared", "number"), true);
				apused.setLink(nodePower.createChild("used", "number"), true);
				
				actionpoints.addBitmapWidget("indicator_linked").setPosition("bottomright", -5, -5);
				actionpoints.setReadOnly(true);
				break;
			end
		end
	end
end

--
-- SECTION VISIBILITY FUNCTIONS
--

function setTargetingVisible(v)
	if activatetargeting.getValue() then
		v = true;
	end
	if type.getValue() ~= "pc" and active.getState() then
		v = true;
	end
	
	targetingon = v;
	targetingicon.setVisible(v);
	
	targeting_add_button.setVisible(v);
	targeting_clear_button.setVisible(v);
	targets.setVisible(v);
	
	frame_targeting.setVisible(v);
	
	onTargetsChanged();
end

function setActiveVisible(v)
	if activateactive.getValue() then
		v = true;
	end
	if type.getValue() ~= "pc" and active.getState() then
		v = true;
	end
	
	activeon = v;
	activeicon.setVisible(v);

	attacks.setVisible(v);
	if v and not attacks.getNextWindow(nil) then
		attacks.createWindow();
	end
	atklabel.setVisible(v);
	immediate_check.setVisible(v);
	init.setVisible(v);
	initlabel.setVisible(v);
	actionpoints.setVisible(v);
	aplabel.setVisible(v);
	
	frame_active.setVisible(v);
end

function setDefensiveVisible(v)
	if activatedefensive.getValue() then
		v = true;
	end
	
	defensiveon = v;
	defensiveicon.setVisible(v);

	ac.setVisible(v);
	aclabel.setVisible(v);
	fortitude.setVisible(v);
	fortitudelabel.setVisible(v);
	reflex.setVisible(v);
	reflexlabel.setVisible(v);
	will.setVisible(v);
	willlabel.setVisible(v);
	save.setVisible(v);
	savelabel.setVisible(v);
	specialdef.setVisible(v);
	specialdeflabel.setVisible(v);
	
	frame_defensive.setVisible(v);
end
	
function setSpacingVisible(v)
	if activatespacing.getValue() then
		v = true;
	end

	spacingon = v;
	spacingicon.setVisible(v);
	
	speed.setVisible(v);
	speedlabel.setVisible(v);
	space.setVisible(v);
	spacelabel.setVisible(v);
	reach.setVisible(v);
	reachlabel.setVisible(v);
	
	frame_spacing.setVisible(v);
end

function setEffectsVisible(v)
	if activateeffects.getValue() then
		v = true;
	end
	
	effectson = v;
	effecticon.setVisible(v);
	
	effects.setVisible(v);
	
	frame_effects.setVisible(v);

	onEffectsChanged();
end

-- Client Visibility

function isClientVisible()
	if type.getValue() == "pc" then
		return true;
	end
	if show_npc.getState() then
		return true;
	end
	return false;
end
