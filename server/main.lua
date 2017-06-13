local skynet = require "skynet"
--local logger = require "logger"
skynet.start(function()
    --[[
	local loginserver = skynet.newservice("logind")
	local gate = skynet.newservice("gated", loginserver)

	skynet.call(gate, "lua", "open" , {
		port = 6174,
		maxclient = 1024,
		servername = "login_server",
	})
    ]]
    --logger.err("%s","start login server ...")
    --skynet.newservice('logger')
    skynet.newservice("logservice")
    skynet.newservice('webclient')
    skynet.newservice('login_3rd')
    skynet.newservice('simpleweb')
end)
