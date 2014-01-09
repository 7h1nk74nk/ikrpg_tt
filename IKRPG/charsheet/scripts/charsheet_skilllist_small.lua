-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



function onInit()
	
	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getNodeName();
	DB.addHandler(sChar ..  ".stats", "onChildUpdate", onStatUpdate);
	DB.addHandler(sChar .. ".skilllist.*.skillstat", "onUpdate", onStatUpdate);
    DB.addHandler(sChar .. ".skilllist.*.rank", "onUpdate", onStatUpdate);
    
    
    
                            
end

function onStatUpdate()
	for _,w in pairs(getWindows()) do
		w.onStatUpdate();
	end
end

function onFilter( w ) 
    if w.rank.getValue()>0 or w.subskillnumber.getValue() > 0 or w.parentskill.getValue() ~= "" then
        w.updateSubStatus();
            w.windowlist.window.emptytext.setVisible(false);
        return true;
    else 
        return false;
    end
end
