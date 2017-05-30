local skynet = require "skynet"
require "skynet.manager"
local const = require "const"
local loglevel = const.loglevel
local logfile = nil
local log_file_name = skynet.getenv("log_file_name") or "skynet.log" 
local log_dir = skynet.getenv("log_dir") or "../log"
local daemon = skynet.getenv("daemon") or nil
local command ={}

local function open_log_file()
    if logfile then
        return true
    end
    if not logfile then
        local log_full_name = log_dir.."/"..log_file_name
        logfile = io.open(log_full_name, "a+")
        if logfile then
            skynet.error(string.format("open log file:%s success", log_full_name))
            return true
        else
            skynet.error(string.format("open log file:%s error", log_full_name))
            return false
        end
    end
    return false 
end
function command.log(source, level, t, msg)
    if not logfile then
        skynet.error("logfile object is nil")
        return
    end
    local lvl_str = "debug"
    if level == loglevel.info then
        lvl_str = "info"
    elseif level == loglevel.warn then
        lvl_str = "warn"
    elseif level == loglevel.err then
        lvl_str = "err"
    else
        skynet.error(string.format("unkonwn log level:%s", level))
        return 
    end
    local t_str = os.date("%Y-%m-%d %H:%M:%S", t)
    local content = string.format("%s [%s] %s\n", t_str, lvl_str, msg)
    logfile:write(content)
    logfile:flush()
    if daemon == nil then
        io.write(content)
        io.flush()
    end
end


skynet.start(function () 
    skynet.dispatch("lua", function(session, source, cmd, ...) 
        local f = command[cmd]
        if f then 
            return f(source, ...)
        else
            skynet.error(string.format("can not found command:%s", cmd))
        end
    end)
    open_log_file()
    skynet.register(".logservice")
end)
