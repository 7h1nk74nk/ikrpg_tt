-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--





function onFilter( w ) 
    
    if w.aquired.getState() then        
        return true;
    else 
        return false;
    end
end
