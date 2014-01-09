-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	registerMenuItem("Remove Effect", "deletepointer", 3);
	registerMenuItem("Confirm Remove", "delete", 3, 3);

	local nodeTargetList = getDatabaseNode().createChild("targets");
	if nodeTargetList then
		nodeTargetList.onChildUpdate = onTargetsChanged;
		nodeTargetList.onChildAdded = onTargetsChanged;
	end
	onTargetsChanged();
end

function onMenuSelection(selection, subselection)
	if selection == 3 and subselection == 3 then
		windowlist.deleteChild(self, true);
	end
end

function onTargetsChanged()
	if target_name then
		local aTargets = {};
		for keyTarget, winTarget in pairs(targets.getWindows()) do
			local nodeTarget = DB.findNode(winTarget.noderef.getValue());
			local sTarget = DB.getValue(nodeTarget, "name", "");
			table.insert(aTargets, sTarget);
		end
		if #aTargets > 0 then
			target_name.setValue("Targets: " .. table.concat(aTargets, ", "));
			target_name.setVisible(true);
		else
			target_name.setValue("");
			target_name.setVisible(false);
		end
	end
end

function onDragStart(button, x, y, draginfo)
	local rEffect = {};
	rEffect.sName = label.getValue();
	rEffect.sExpire = expiration.getStringValue();
	rEffect.nSaveMod = effectsavemod.getValue();
	rEffect.nInit = effectinit.getValue();
	rEffect.sSource = source_name.getValue();
	rEffect.nGMOnly = isgmonly.getIndex();
	rEffect.sApply = apply.getStringValue();

	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function onDrop(x, y, draginfo)
	if draginfo.isType("combattrackerentry") then
		local nodeCTSource = draginfo.getCustomData();
		if nodeCTSource then
			local nodeWin = windowlist.window.getDatabaseNode();
			if nodeWin then
				if nodeCTSource.getNodeName() == nodeWin.getNodeName() then
					source.setSource("");
				else
					source.setSource(nodeCTSource.getNodeName());
					effectinit.setValue(DB.getValue(nodeCTSource, "initresult", 0));
				end
			end
		end
		return true;
	end
end

function onExpirationChanged()
	local sExpiration = expiration.getStringValue();
	if sExpiration == "endnext" or sExpiration == "start" or sExpiration == "end" then
		if source_name.getValue() == "" then
			local nActiveInit = CTManager.getActiveInit();
			if nActiveInit then
				effectinit.setValue(nActiveInit);
			end
		end
		effectinit.setVisible(true);
		effectsavemod.setVisible(false);
	elseif sExpiration == "save" then
		effectinit.setValue(windowlist.window.initresult.getValue());
		effectinit.setVisible(false);
		effectsavemod.setVisible(true);
	else
		effectinit.setValue(windowlist.window.initresult.getValue());
		effectinit.setVisible(false);
		effectsavemod.setVisible(false);
	end
end
