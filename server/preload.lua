-- This file will execute before every lua service start
-- See config
package.path = '../server/?.lua;../common/?.lua;'..package.path..';'
package.cpath = package.cpath..";./cservice/?.so;../luaclib/?.so;"

