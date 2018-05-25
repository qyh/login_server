local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local logger = require "logger"
local idx = 0

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        logger.err('fd = %d, %s', id, err)
    end
end

local function _req_dispatch(id, addr, idx)
	socket.start(id)
    logger.info('id:%s, addr:%s, idx:%s', id, addr, idx)
    local code, url, method, header, body = httpd.read_request(
        sockethelper.readfunc(id),
        8192)
    if code then
        if code ~= 200 then
            response(id, code)
        else
            local path, query = urllib.parse(url)
            local msg = string.format("you are the %d visitor!", idx)
            response(id, code, msg.."\n\n")
        end
    else
        response(id, 403)
    end
	logger.err('upgrade:%s,HTTP2-Settings:%s', header['Upgrade'], header['HTTP2-Settings'])
    socket.close(id)
end

skynet.start(function()
    local port = 80
    local id = socket.listen("0.0.0.0", port)
    logger.info('webserver listen on :%s, listen id:%s', port, id)

    socket.start(id, function(id, addr)
        idx = idx + 1
        skynet.fork(_req_dispatch, id, addr, idx)
        logger.info('%s connected,id:%s', addr,id)
    end)
end)
