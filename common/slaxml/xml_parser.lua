local SLAXML = require "slaxml"
local xml_parser = {}
local root = {} 
local ele_list = {}

local function start_element(name, nsURI, nsPrefix)
    local ele = {}
    table.insert(ele_list, ele)
end

local function attribute(name, value, nsURI, nsPrefix)
    local ele = ele_list[#ele_list]
    local prop = ele["prop"] or {}
    prop[name] = value
    ele["prop"] = prop
end

local function close_element(name, nsURI)
    local ele = ele_list[#ele_list]
    if #ele_list > 1 then
        local ele_p = ele_list[#ele_list - 1]
        ele_p[name] = ele
    else
        root[name] = ele
    end
    table.remove(ele_list, #ele_list)
end

local function text(t)
    local ele = ele_list[#ele_list]
    ele["value"] = t
end

local function comment(content)
end
local function pi(target, content)
end


function xml_parser:parse_xml_text(t)
    local parser = SLAXML:parser{
        startElement = start_element,
        attribute = attribute,
        closeElement = close_element,
        text = text,
        comment = comment,
        pi = pi,
    }
    print('parse_text:', t)
    parser:parse(t, {stripWhitespace=true})

    return root 
end

return xml_parser

