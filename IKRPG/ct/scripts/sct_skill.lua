-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local iscustom = true;

function onInit()
	setRadialDeleteOption();

	results.getDatabaseNode().onChildAdded = onResultsChanged;
	results.getDatabaseNode().onChildUpdate = onResultsChanged;
	onResultsChanged();
end

function setCustom(flag)
	iscustom = flag;
	
	if not iscustom then
		label.setEnabled(false);
		label.setFrame(nil);
	end

	setRadialDeleteOption();
end

function setRadialDeleteOption()
	resetMenuItems();
	
	if iscustom then
		registerMenuItem("Delete Custom Skill", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		getDatabaseNode().delete();
		SCManager.calcTotals();
	end
end

function onResultsChanged()
	if (results.getDatabaseNode().getChildCount() > 0) then
		activate_results.setVisible(true);
	else
		activate_results.setVisible(false);
		activate_results.setValue(false);
	end
	
	SCManager.calcTotals();
end
