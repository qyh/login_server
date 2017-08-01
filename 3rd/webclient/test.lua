local webclientlib = require 'webclient_core'
local webclient = webclientlib.create()

local urls = {
	"http://127.0.0.1:8004/index.html",
	"http://127.0.0.1:8003/wechat/login.do",
}
webclient:set_timeout_ms(300003);
local requests = {};
for i, v in ipairs(urls) do

    local header1 = "Content-Type:application/x-www-form-urlencoded;charset=utf-8"
	local req, key = webclient:request(v, nil, nil, header1)
	assert(req)
	assert(key)
	requests[key] = {req, v}

    if i == 1 then
        webclient:debug(req, true)
    end
end

while next(requests) do
	local finish_key = webclient:query()
	if finish_key then
		assert(requests[finish_key])

		local req, url = table.unpack(requests[finish_key])
		local content, errmsg = webclient:get_respond(req)
		local info = webclient:get_info(req)
		print(url, #content, errmsg, info.ip, info.port, info.content_length, info.response_code)
		webclient:remove_request(req)
		requests[finish_key] = nil
	end
end 
print("test webclient finish!")
