-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		registerMenuItem("Rest", "lockvisibilityon", 8);
		registerMenuItem("Short Rest", "pointer_cone", 8, 8);
		registerMenuItem("Short Rest + Milestone", "pointer_square", 8, 7);
		registerMenuItem("Extended Rest", "pointer_circle", 8, 6);
	end
	
	if User.isLocal() then
		portrait.setVisible(false);
		localportrait.setVisible(true);
	end
end

function onMenuSelection(selection, subselection)
	if selection == 8 then
		if subselection == 8 then
			ChatManager.Message("Taking short rest.", true, ActorManager.getActor("pc", getDatabaseNode()));

			CharManager.rest(getDatabaseNode());
		elseif subselection == 7 then
			ChatManager.Message("Taking short rest. Milestone reached.", true);

			CharManager.rest(getDatabaseNode(), false, true);
		elseif subselection == 6 then
			ChatManager.Message("Taking extended rest.", true, ActorManager.getActor("pc", getDatabaseNode()));

			CharManager.rest(getDatabaseNode(), true);
		end
	end
end
