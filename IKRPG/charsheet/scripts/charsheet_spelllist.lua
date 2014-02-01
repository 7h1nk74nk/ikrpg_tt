-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--



function onInit()
	if window.parentcontrol.window.main.subwindow.careers.getValue()=="" then
    else
	registerMenuItem("Create", "insert", 5);
	

	constructSpellList();

	local nodeChar = getDatabaseNode().getParent();
	local sChar = nodeChar.getNodeName();
	--DB.addHandler(sChar ..  ".stats", "onChildUpdate", onStatUpdate);
	--DB.addHandler(sChar .. ".skilllist.*.skillstat", "onUpdate", onStatUpdate);
    DB.addHandler(sChar .. ".career1", "onUpdate", applyFilter);    
	DB.addHandler(sChar .. ".career2", "onUpdate", applyFilter);    
	DB.addHandler(sChar .. ".career3", "onUpdate", applyFilter);    
	DB.addHandler(sChar .. ".career4", "onUpdate", applyFilter);    
	DB.addHandler(sChar .. ".career5", "onUpdate", applyFilter);    
    applyFilter();	
	end
end


function addEntry(bFocus)
	local win = NodeManager.createWindow(self);
	win.setCustom(true);
    --win.order.setValue(-1);
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

spellList={};


function constructSpellList()

	for spellname,spellinfo in pairs(DataCommon.spelldescriptions) do
		spellList[spellname]=addSpell(spellname);
	end
	
	for k,v in pairs(getWindows()) do
		name=v.label.getValue();
		if not spellList[name] then
			spellList[name]=v;
		end
	end

end

function addSpell(name)
	local node = getDatabaseNode().getChild(name);
    local win = nil;
    if not node then
        --node = getDatabaseNode().createChild(name);
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
		spellinfo=DataCommon.spelldescriptions[name];
        
		if win.aquired.getState() then
			win.order.setValue(spellinfo.order-10000);
		else
			win.order.setValue(spellinfo.order);
		end
		
		win.label.setValue(name);        	
		win.cost.setValue(spellinfo.cost);
		win.range.setValue(spellinfo.range);
		
		win.aoe.setValue(spellinfo.aoe);		
		win.power.setValue(spellinfo.power);
		
		win.upkeep.setValue(spellinfo.upkeep);
		win.offensive.setValue(spellinfo.offensive);
		win.description.setValue(spellinfo.description);
		
		
					
    end
    return win;
end


function setContains(set, key)
    return set[key] ~= nil
end

function trim(s)
  return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

errorcount=0;
function onFilter( w ) 
   
	local skillwindow=w.windowlist.window.getDatabaseNode();
	
	local careers={};
	if skillwindow.getChild("career1") then
		careers[1]=skillwindow.getChild("career1").getValue();
	end
	
	if skillwindow.getChild("career2") then
	 careers[2]=skillwindow.getChild("career2").getValue();
	end
	
	if skillwindow.getChild("career3") then
		careers[3]=skillwindow.getChild("career3").getValue();
	end
	
	if skillwindow.getChild("career4") then
		careers[4]=skillwindow.getChild("career4").getValue();
	end
	
	if skillwindow.getChild("career5") then
		careers[5]=skillwindow.getChild("career5").getValue();
	end
				
	
	local inList=false;
	
	if DataCommon.spelldescriptions[w.label.getValue()]==nil then
		inList=true
	end
	
	
	
    
	 for i,nextcareer in ipairs(careers) do
        nextcareer=trim(nextcareer);                        
        if DataCommon.spelllists[nextcareer]~= nil then                                   						            			
			for index,spellname in pairs(DataCommon.spelllists[nextcareer]) do			
				if spellname==w.label.getValue() then
					inList=true;                							
				end
			end
			
        end
    end
	
	
	
	
	if w.aquired.getState() then inList=true; end
	
	if w.windowlist.window.getDatabaseNode().getChild("showAll").getValue() then
		inList=true; 
	end
	
	
	
	return inList;
    
end


