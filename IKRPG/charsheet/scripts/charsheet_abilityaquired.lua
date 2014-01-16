function findWindow(name)
	for k,v in pairs(window.windowlist.getWindows()) do
		if v.label.getValue()==name then 
			return v; 
		end
	end
end




function onValueChanged()
	--print (window.label.getValue().." Aquired changed");
	
	if window.parentability.getValue()~="" then
		
		
		
		local parentNode=DB.findNode(window.parentability.getValue());
		local parentwindow=findWindow(parentNode.getChild("label").getValue());
		
		local aquiredChildren=parentwindow.countAquiredChildWindows();
		
		
		if getState() and aquiredChildren==1 then		
			
			--parentwindow.order.setValue(window.order.getValue()-10000);
			parentwindow.aquired.setState(true);
			
		elseif  aquiredChildren==0	then														
			--parentwindow.order.setValue(window.order.getValue()+10000);							
			parentwindow.aquired.setState(false);
		end
		
	else
	
		local name = window.label.getValue();
		local abilityinfo = DataCommon.abilitydata[name];
		if abilityinfo then
			if getState() then													
				window.order.setValue(abilityinfo.order - 10000);							
			else															
				window.order.setValue(abilityinfo.order);							
			end
		end
		
	end

end