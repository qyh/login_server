local SLAXML = require "slaxml"
local myxml = io.open('test.xml'):read('*all')
SLAXML:parse(myxml)

