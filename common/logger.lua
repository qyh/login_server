local skynet = require "skynet"
local logger = {}
local const = require "const"
local loglevel = const.loglevel

local function log(level, t, fmt, ...)
    local ok, msg = pcall(string.format, fmt, ...)
    if not ok then
        skynet.error("string format error on log")
        return 
    end
    skynet.send(".logservice", "lua", "log", level, t, msg)
end

function logger.debug(fmt, ...)
    local t = os.time()
    log(loglevel.debug, t, fmt, ...)
end

function logger.info(fmt, ...)
    local t = os.time()
    log(loglevel.info, t, fmt, ...)
end

function logger.warn(fmt, ...)
    local t = os.time()
    log(loglevel.warn, t, fmt, ...)
end

function logger.err(fmt, ...)
    local t = os.time()
    log(loglevel.err, t, fmt, ...)
end
return logger


