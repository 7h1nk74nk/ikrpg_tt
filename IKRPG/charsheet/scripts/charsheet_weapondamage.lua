-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local rActor, rDamage, rFocus = CharManager.getAdvancedRollStructures("damage", nil, window.getDatabaseNode());
	
	ActionDamage.performRoll(draginfo, rActor, rDamage, rFocus);
	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end

function onDoubleClick(x,y)
	return action();
end			
