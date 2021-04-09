local Item = {
    Icon = "", --// required, this is what shows up in the toolbar
    Model = nil,  --// not required, the model attached to this item
    Name = "Example" --// required, the displayed name of this tool
}

function Item:Initialize() --// called when the player adds the item to their inventory. Should not yield, only for connection or animation initialization

end

function Item:Drop() --// called when the player drops the item, can yield for animations

end

function Item:Equip() --// called when a player equips an item, can yield for animations

end

function Item:Unequip() --// called when a player unequips an item, can yield for animations

end

function Item:Destroy() --// called when an item is destroyed, can yield for animations, but it is not recommended.

end

return Item