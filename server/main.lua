local skynet = require "skynet"

skynet.start(function()
	local loginserver = skynet.newservice("logind")
	local gate = skynet.newservice("gated", loginserver)

	skynet.call(gate, "lua", "open" , {
		port = 6174,
		maxclient = 1024,
		servername = "login_server",
	})
    skynet.newservice('login_3rd')
end)
