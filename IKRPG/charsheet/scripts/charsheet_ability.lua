-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



sets = {};
hasSubAbilities=false;
iscustom=true;
--parentwindow=nil;
childwindows={};

function onInit()
	--print();
	--print("onInit");
	setCustom(true);
	parentability.getDatabaseNode().onUpdate=updateSubStatus;
	setRadialOptions();    
	updateSubStatus();    
	
	if(parentability.getValue()~="") then
		parentOrderChanged();
	end
end

function findWindow(name)
	for k,v in pairs(windowlist.getWindows()) do
		if v.label.getValue()==name then 
			return v; 
		end
	end
end

function countAquiredChildWindows()
	
	local result=0;
	
	for k,v in pairs(windowlist.getWindows()) do
		if v.parentability.getValue()==self.getDatabaseNode().getNodeName() and v.aquired.getState() then 
			result=result+1; 
		end
	end
	
	return result;
end

function updateSubStatus()
	--print();
	--print ("UpdateSubStatis: Called");
    if parentability.getValue()=="" then
		--print ("  UpdateSubStatis: No parentability");
    else
		--print ("  UpdateSubStatis: working");
        setCustom(true);
		aquired.setAnchor("left", "", "left","absolute",30);
        aquired.setAnchor("top", "", "top","absolute",5);
        label.setAnchoredWidth(230);
        label.setAnchor("left", "", "left","absolute",55);
        label.setAnchor("top", "", "top","absolute",5);
        label.setAnchoredWidth(210);
        --wnd.skilltype.setVisible(false);
        --wnd.skillstat.setVisible(false);
        --wnd.max.setVisible(false);
        
        
        --local parentmax=DB.findNode(parentskill.getValue()..".max").getValue();        
       -- max.setValue(parentmax);        
	   
		DB.findNode(parentability.getValue()).getChild("order").onUpdate=parentOrderChanged;
		--local parentNode=DB.findNode(parentability.getValue());
		--parentwindow=findWindow(parentNode.getChild("label").getValue());
    end
end


function checkPrereq(abilityname)
end

function onMenuSelection(selection, subselection)
	if selection == 6 and subselection == 7 then
		--aquired.setState(false);
		delete()
	end

	 if selection == 2 then
		addSubAbility(self.label.getValue().." ()");		
	end
end

function delete()
	
	local updateParent=aquired.getState() and parentability.getValue()~="";
	local parentNode=DB.findNode(parentability.getValue());
	local parentwindow=nil;
	if parentNode.getChild("label") then
		parentwindow=findWindow(parentNode.getChild("label").getValue());
	end
	
	local node = getDatabaseNode();
	if node then            
		local parentabilitynum=DB.findNode(parentability.getValue()).getChild("subabilitynumber");		
		if parentabilitynum then
            parentabilitynum.setValue(parentabilitynum.getValue()-1);					
		end
		node.delete();
	else         
		local parentabilitynum=DB.findNode(parentability.getValue()).getChild("subabilitynumber");		
		if parentabilitynum then
            parentabilitynum.setValue(parentabilitynum.getValue()-1);		
		end
		close();
	end
	
	if updateParent and parentwindow then
		
		local aquiredChildren=parentwindow.countAquiredChildWindows();
		print("update parent "..aquiredChildren);
		
		if aquiredChildren==0 then					
			parentwindow.aquired.setState(false);					
		end
		
	end
end

function addSubAbility(name)

	local wnd = self.windowlist.addEntry(false);
	self.windowlist.abilityList[name]=wnd;
	if wnd then
		
		--self.order.getDatabaseNode().onUpdate=wnd.parentOrderChanged;
		self.subabilitynumber.setValue(self.subabilitynumber.getValue()+1);		
		
		wnd.order.setValue(self.order.getValue());		
		wnd.label.setValue(name);
		wnd.parentability.setValue(self.getDatabaseNode().getNodeName());
		--print();
		--print("addSubAbility: parent ability set to "..self.getDatabaseNode().getNodeName());
		--wnd.type.setValue(self.type.getValue());		
		wnd.type.setValue("Custom");		
		wnd.prerequisite.setValue(self.prerequisite.getValue());
		wnd.description.setValue(self.description.getValue());
        wnd.shortdesc.setValue(self.shortdesc.getValue());   						
		wnd.updateSubStatus();
		
		
		return wnd;
	end

	
end

function parentOrderChanged(source)
	--print (label.getValue());
	--print ("parent order changed");
	--print(parentability.getValue());
	order.setValue(DB.findNode(parentability.getValue()).getChild("order").getValue());
end

-- This function is called to set the entry to non-custom or custom.
-- Custom entries have configurable stats and editable labels.
function setCustom(state)
	iscustom = state;
	
	if iscustom then
		type.setValue("Custom");
		label.setEnabled(true);
		label.setLine(true);
        prerequisite.setEnabled(true);
		description.setEnabled(true);
        label.setFrame("");
		label.setLine(true,-1);
		label.setColor("FF000000");
		
	else
		label.setEnabled(false);
		label.setLine(false);
		prerequisite.setEnabled(false);
		description.setEnabled(false);	
		label.setLine(false);
		label.setColor("FFFFFFFF");		
	end
	
	if type.getValue()=="Ability" then		
		label.setFrame("headerpoweratwill");
	elseif type.getValue()=="Custom" then
		label.setFrame("");
	else
		label.setFrame("headerparcel");		
	end
		
	setRadialOptions();
end

function setHasSubAbilities(state)    
    aquired.setVisible(not state);    
    hasSubAbilities=state;
    setRadialOptions();
end

function setRadialOptions()
	resetMenuItems();

	if iscustom then
		registerMenuItem("Delete", "delete", 6);
		registerMenuItem("Confirm Delete", "delete", 6, 7);
	end
	if hasSubAbilities then
        registerMenuItem("Add Subability", "insert", 2);		
    end
    
end

