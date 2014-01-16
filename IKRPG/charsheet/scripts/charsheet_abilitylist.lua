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
	DB.addHandler(sChar .. ".race", "onUpdate", applyFilter);
	applyFilter();		
end



function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	win.type.setValue("Custom");
	win.setCustom(true);
	win.order.setValue(-1);
	
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
	
	for k,v in pairs(getWindows()) do
		name=v.label.getValue();
		
		if not abilityList[name] then
			--print(name);
			--print (v.parentability.getValue());
			abilityList[name]=v;
			--if v.parentability and v.parentability.getValue()~="" then
				--print (v.parentability.getValue());
				--parentNode=DB.findNode(v.parentability.getValue());
				--v.order.setValue(parentNode.getChild("order").getValue());
			--end
		end
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
		win.setHasSubAbilities(abilityinfo.multiability);
		--if abilityinfo.multiability then print( name); end
		if win.aquired.getState()   then
			win.order.setValue(abilityinfo.order-10000);
		else
			win.order.setValue(abilityinfo.order);
		end
        win.type.setValue(abilityinfo.type);
        win.prerequisite.setValue("Prerequisite: "..abilityinfo.prereq);
        win.description.setValue(abilityinfo.desc);
        win.shortdesc.setValue(abilityinfo.shortdesc);        						
		if abilityinfo.type=="Ability" then
			win.label.setFrame("headerpoweratwill");
		else
			win.label.setFrame("headerparcel");
		end
    end
    return win;
end


function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function onFilter( w ) 
	
	archetype=w.windowlist.window.getDatabaseNode().getChild("archetype").getValue();
	--careers=StringManager.split(w.windowlist.window.getDatabaseNode().getChild("careers").getValue(),",");
	
	local careers={};
	careers[1]=w.windowlist.window.career1.getValue();
	careers[2]=w.windowlist.window.career2.getValue();
	careers[3]=w.windowlist.window.career3.getValue();
	careers[4]=w.windowlist.window.career4.getValue();
	careers[5]=w.windowlist.window.career5.getValue();
	
	local race="";
	race=w.windowlist.window.getDatabaseNode().getChild("race").getValue();
	
	
	
	local inList=false;
	
	if DataCommon.abilitydata[w.label.getValue()]==nil then
		inList=true
	end
	
	--if w.subabilitynumber.getValue()>0 then
		--inList=true;
	--end
	
    if w.type.getValue()==archetype  then --Display all if no archetype is selected:  or ( archetype=="" and  (w.type.getValue()=="Mighty" or w.type.getValue()=="Skilled" or w.type.getValue()=="Gifted" or w.type.getValue()=="Intellectual") ) then                
        inList=true;
    end
	
	 for i,nextcareer in ipairs(careers) do
        nextcareer=trim(nextcareer);                        
        if DataCommon.careers[nextcareer]~= nil then                                   						
            if DataCommon.careers[nextcareer].abilities[w.label.getValue()]~=nil then
                inList=true;                							
            end
        end
    end
	
	
	if DataCommon.racedata[race]~=nil then
		if DataCommon.racedata[race].Abilities[w.label.getValue()]~=nil then		
			inList=true;					
		end
	end
	
	if w.aquired.getState()  then inList=true; end
	
	if w.windowlist.window.showAll.getState() then
		inList=true; 
	end
	
	 if w.parentability.getValue() ~= "" then inList = true; end
	
	return inList;
end
