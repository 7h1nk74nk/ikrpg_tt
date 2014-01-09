-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



function onInit()
	registerMenuItem("Create", "insert", 5);
	

    constructAbilityList();

  
	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getNodeName();
    DB.addHandler(sChar .. ".archetype", "onUpdate", applyFilter);
end



function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	win.setCustom(true);
	if bFocus and win then        
		win.label.setFocus();
	end
	return win;
end

function onMenuSelection(item)
	if item == 5 then
		addEntry(true);
	end
end

abilityList={};

function constructAbilityList()

	for abilityname,abilityinfo in pairs(DataCommon.abilitydata) do
		abilityList[abilityname]=addAbility(abilityname);
	end

end

function addAbility(name)
	local node = getDatabaseNode().getChild(name);
    local win = nil;
    if not node then        
		win = NodeManager.createWindow(self,getDatabaseNode().getNodeName().."."..name);
		win.setCustom(false);
    else	
		for i,w in ipairs(getWindows()) do
			if w.label.getValue()==name then
				win = w;
				win.setCustom(false);
			end
		end
	end
	
    if win then
		abilityinfo=DataCommon.abilitydata[name];
        win.label.setValue(name);
        win.order.setValue(abilityinfo.order);
        win.type.setValue(abilityinfo.type);
        win.prerequisite.setValue(abilityinfo.prereq);
        win.description.setValue(abilityinfo.desc);
        win.shortdesc.setValue(abilityinfo.shortdesc);        						
    end
    return win;
end




function onFilter( w ) 
	archetype=w.windowlist.window.getDatabaseNode().getChild("archetype").getValue();
	careers=w.windowlist.window.getDatabaseNode().getChild("careers").getValue();
	
    if w.type.getValue()==archetype or ( archetype=="" and  (w.type.getValue()=="Mighty" or w.type.getValue()=="Skilled" or w.type.getValue()=="Gifted" or w.type.getValue()=="Intellectual") ) then                
        return true;
    else 
        return false;
    end
end
