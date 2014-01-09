-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local widgeticon = nil;
local nOffsetX = 5;
local nOffsetY = 12;

function onInit()
	if offset then
		local sOffsetX, sOffsetY = string.match(offset[1], "^(%d+),(%d+)$");
		if sOffsetX and sOffsetY then
			nOffsetX = tonumber(sOffsetX) or 5;
			nOffsetY = tonumber(sOffsetY) or 12;
		end
	end
	
	if anchor then
		setAnchor("top", anchor[1], "bottom", "relative", nOffsetY);
	elseif window.columnanchor then
		setAnchor("top", "columnanchor", "bottom", "relative", nOffsetY);
	else
		setAnchor("top", "", "top", "absolute", nOffsetY);
	end
	
	setAnchor("left", "", "left", "absolute", nOffsetX);
	setAnchor("right", "", "right", "absolute", -nOffsetX);
	
	if target then
		setWidget(true);
	end
end

function setWidget(bVisible)
	if widgeticon then
		widgeticon.destroy();
		widgeticon = nil;
	end
	
	if bVisible then
		widgeticon = addBitmapWidget("collapse_icon");
	else
		widgeticon = addBitmapWidget("expand_icon");
	end
	widgeticon.setSize(10, 10);
	widgeticon.setPosition("topright", -(nOffsetX + 5), 7);
end

function onClickDown(button, x, y)
	return true;
end

function onClickRelease(button, x, y)
	if target then
		local ctrl = window[target[1]];
		local bVisible = not ctrl.isVisible();
		
		ctrl.setVisible(bVisible);
		
		setWidget(bVisible);
	end
end
