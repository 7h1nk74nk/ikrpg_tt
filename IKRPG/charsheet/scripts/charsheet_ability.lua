-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



sets = {};

function onInit()
	setRadialOptions();    
	
    
end


function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		local node = getDatabaseNode();
		if node then            
			node.delete();
		else            
			close();
		end
	end            
end



-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);
        prerequisite.setEnabled(true);
		description.setEnabled(true);
        
	else
		label.setEnabled(false);
		label.setLine(false);
		prerequisite.setEnabled(false);
		description.setEnabled(false);
       
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

