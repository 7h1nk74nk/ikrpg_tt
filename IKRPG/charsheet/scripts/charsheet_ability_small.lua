-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



sets = {};
hasSubAbilities=false;
iscustom=true;

function onInit()	
	updateSubStatus();
    
end

function updateSubStatus()
    if parentability.getValue()=="" then
    else
		--print (parentability.getValue());
		
        setCustom(true);		
		
    end
end


-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		label.setEnabled(true);
		label.setLine(true);        
		description.setEnabled(true);
        label.setFrame("");
		label.setLine(true,-1);
		label.setColor("FF000000");
		
	else
		label.setEnabled(false);
		label.setLine(false);		
		description.setEnabled(false);		
	end
	
	if type.getValue()=="Ability" then		
		label.setFrame("headerpoweratwill");
	elseif type.getValue()=="Custom" then
		label.setFrame("");
	else
		label.setFrame("headerparcel");		
	end
			
end

function setHasSubAbilities(state)    
    aquired.setVisible(not state);    
    hasSubAbilities=state;

end

