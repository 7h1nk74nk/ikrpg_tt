-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--




function onFilter( w ) 
    if w.rank.getValue()>0 or w.subskillnumber.getValue() > 0 or w.parentskill.getValue() ~= "" then
        w.updateSubStatus();            
        return true;
    else 
        return false;
    end
end
