-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	onLevelChanged();
end

function onLevelChanged()
	local nLevel = level.getValue();
	if nLevel > 20 then
		class.setVisible(false);
		paragon.setVisible(false);
		epic.setVisible(true);
	elseif nLevel > 10 then
		class.setVisible(false);
		paragon.setVisible(true);
		epic.setVisible(false);
	else
		class.setVisible(true);
		paragon.setVisible(false);
		epic.setVisible(false);
	end
end

