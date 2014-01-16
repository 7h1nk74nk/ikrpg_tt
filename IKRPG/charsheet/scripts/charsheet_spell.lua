-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

iscustom = true;

function onInit()
	setRadialOptions();
    
end


function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		delete();
	end
    
    
end

function delete() 

	windowlist.spellList[label.getValue()]=nil;
		window.aquired.setState(false);
		local node = getDatabaseNode();
		if node then
			node.delete();
		else			
			close();
		end
		
end



-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
		cost.setEnabled(true);
		cost.setLine(true);
		range.setEnabled(true);
		range.setLine(true);
		aoe.setEnabled(true);
		aoe.setLine(true);
		power.setEnabled(true);
		power.setLine(true);
		upkeep.setEnabled(true);
		upkeep.setLine(true);
		offensive.setEnabled(true);
		offensive.setLine(true);
		description.setEnabled(true);
		description.setLine(true);
        --skillstat.setFrame("bonus",5,5,5,5);
		--skillstat.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
		--skillstat.setReadOnly(false);
        --skilltype.setFrame("bonus",5,5,5,5);
        --skilltype.setStateFrame("hover", "sheetfocus", 6, 5, 6, 5);
        --skilltype.setReadOnly(false);
	else
		label.setEnabled(false);
		label.setLine(false);
		cost.setEnabled(false);
		cost.setLine(false);
		range.setEnabled(false);
		range.setLine(false);
		aoe.setEnabled(false);
		aoe.setLine(false);		
		power.setEnabled(false);
		power.setLine(false);
		upkeep.setEnabled(false);
		upkeep.setLine(false);
		offensive.setEnabled(false);
		offensive.setLine(false);
		description.setEnabled(false);
		description.setLine(false);
        --skillstat.setFrame(nil);
		--skillstat.setStateFrame("hover", nil);
		--skillstat.setReadOnly(true);
        --skilltype.setFrame(nil);
        --skilltype.setStateFrame("hover", nil);
		--skilltype.setReadOnly(true);
	end
	
	setRadialOptions();
end


function setRadialOptions()
	resetMenuItems();

	if iscustom then
		registerMenuItem("Delete", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
end

