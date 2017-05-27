local url = {}

local function decode_func(c)
	return string.char(tonumber(c, 16))
end

local function decode(str)
	local str = str:gsub('+', ' ')
	return str:gsub("%%(..)", decode_func)
end

function url.parse(u)
	local path,query = u:match "([^?]*)%??(.*)"
	if path then
		path = decode(path)
	end
	return path, query
end

function url.parse_query(q)
	local r = {}
	for k,v in q:gmatch "(.-)=([^&]*)&?" do
		r[decode(k)] = decode(v)
	end
	return r
end


local query ='buyer_id=2088002144715570&total_amount=0.10&trade_no=2017041121001004570284760578&body=%E7%AB%9E%E6%8A%80%E5%8D%A1x1&notify_time=2017-04-11+17%3A09%3A04&subject=%E7%AB%9E%E6%8A%80%E5%8D%A1x1&sign_type=RSA&auth_app_id=2017022105800603&charset=UTF-8&notify_type=trade_status_sync&invoice_amount=0.10&out_trade_no=pd-20170411154520-11-51004002&trade_status=TRADE_SUCCESS&gmt_payment=2017-04-11+15%3A45%3A49&version=1.0&point_amount=0.00&sign=o2WhsZfdc%2BlmNp90xsyy5%2FmwXlg24kqjIGr56Gtr3jN2zXpkhVuARq497QHCWOhj99dLjknXZKT2c%2BGhIuuATPn1cEwhhE%2FGvylPQAtV2L1TdnI2DamZa7l%2FE8pR6xFt2U5OT6hN%2FiU5%2B5%2BAIPvcVi0JGHymYBiwMZuFfLpYqaE%3D&gmt_create=2017-04-11+15%3A45%3A38&buyer_pay_amount=0.10&receipt_amount=0.10&passback_params=merchantBizType%253d3C%2526merchantBizNo%253d2016010101111&fund_bill_list=%5B%7B%22amount%22%3A%220.10%22%2C%22fundChannel%22%3A%22ALIPAYACCOUNT%22%7D%5D&app_id=2017022105800603&seller_id=2088521387999436&notify_id=fbe271ba8d140ac6e1fa8e284fd5140kee'
print(decode(query))
