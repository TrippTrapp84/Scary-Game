--// SERVICES
local RepStore = game:GetService("ReplicatedStorage")

--// REQUIRES

--// TYPE DECLARATIONS
type Dictionary = {[any] : any}

--// LOCAL FUNCTIONS
local function DeepCopy(FromTable : Dictionary,ToTable : Dictionary)
    for i,v in pairs(FromTable) do
        if typeof(v) == "table" then v = DeepCopy(v,{}) end
        ToTable[i] = v
    end
    return ToTable
end

--// DATA TABLES
local DefaultValues = {
    "UseType",
    "Icon",
    "Model",
    "Name",
    "Drop",
    "Equip",
    "Unequip",
    "Destroy"
}

--// CONSTRUCTOR
local function MakeItem(Data : Dictionary)
    if not Data then error("Missing data for Item constructor") end
    local Item = {}

    for i,v in pairs(Data) do
        if typeof(Data[i]) == "table" then
            Data[i] = DeepCopy(Data[i],{})
        end
        Item[i] = Data[i]
    end

    return Item
end

return MakeItem