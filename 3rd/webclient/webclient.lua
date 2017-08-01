--- webclient. (skynet服务).
--
-- @module webclient
-- @usage local webclient = skynet.newservice("webclient")


local skynet = require "skynet"
require "skynet.manager"
local webclientlib = require "webclient_core"
local logger = require "logger"
local skynet_util = require "skynet_util"
local webclient = webclientlib.create()
local requests = nil

local function resopnd(request)
    if not request.response then
        return
    end

    local content, errmsg = webclient:get_respond(request.req)  
    if not errmsg then
        request.response(true, true, content)
    else
        local info = webclient:get_info(request.req) 
        if info.response_code == 200 and not info.content_save_failed then
            request.response(true, true, content, errmsg)
        else
            request.response(true, false, errmsg, info)
        end
    end
end

local function query()
    while next(requests) do
        local finish_key = webclient:query()
        if finish_key then
            local request = requests[finish_key];
            assert(request)

            xpcall(resopnd, function() logger.err(debug.traceback()) end, request)

            webclient:remove_request(request.req)
            requests[finish_key] = nil
        else
            skynet.sleep(1)
        end
    end 
    requests = nil
end

local CMD = {}
--- 请求某个url
-- @function request
-- @string url url
-- @tab[opt] get get的参数
-- @param[opt] post post参数，table or string类型 
-- @header[opt] header 参数 , table: {['Content-Type']="application/x-www-form-urlencoded;charset=utf-8"}
-- @treturn bool 请求是否成功
-- @treturn string 当成功时，返回内容，当失败时，返回出错原因 
-- @usage skynet.call(webclient, "lua", "request", "http://www.dpull.com")
-- @usage skynet.send(webclient, "lua", "request", "http://www.dpull.com", nil, nil, header)
function CMD.request(session, url, get, post, header)
    if get then
        local i = 0
        for k, v in pairs(get) do
            k = webclient:url_encoding(k)
            v = webclient:url_encoding(v)

            url = string.format("%s%s%s=%s", url, i == 0 and "?" or "&", k, v)
            i = i + 1
        end
    end

    if post and type(post) == "table" then
        local data = {}
        for k,v in pairs(post) do
            k = webclient:url_encoding(k)
            v = webclient:url_encoding(v)

            table.insert(data, string.format("%s=%s", k, v))
        end   
        post = table.concat(data , "&")
    end   

    local header_list = {}
	if header then
		for k,v in pairs(header) do
			table.insert(header_list, string.format("%s:%s", k, v))
		end
	end

    local req, key = webclient:request(url, post, table.unpack(header_list))
    if not req then
        return skynet.ret()
    end
    assert(key, 'webclient:request key return nil!!')

    local response = nil
    if session ~= 0 then
        response = skynet.response()
    end

    if requests == nil then
        requests = {}
        skynet.fork(query)
    end

    requests[key] = {
        url = url, 
        req = req,
        response = response,
    }
end

function CMD.get(session, url, form, header)
    return CMD.request(session, url, form, nil, header)
end

function CMD.post(session, url, form, header)
    return CMD.request(session, url, nil, form, header)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, command, ...)
		local cmd = string.lower(command)
        local f = CMD[cmd]
        if not f then
            return error(string.format("%s Unknown command %s", SERVICE_NAME, tostring(cmd)))
        end
        local ok, err = xpcall(f, skynet_util.handle_err, session, ...)
		if not ok then
			error(err)
		end
    end)
	skynet.register ".webclient"
end)
