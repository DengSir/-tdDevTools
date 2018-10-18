-- Tests.lua
-- @Author : DengSir (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 10/17/2018, 11:06:29 AM

local function Tests(args)
    LibStub('AceLocale-3.0'):NewLocale('Tests', 'enUS')
    LibStub('AceLocale-3.0'):NewLocale('Tests', 'zhCN', nil, true)

    print('number', 1, -5, 3.14)
    print('string', 'hello', 'world')
    print('boolean', true, false)
    print('nil', nil)
    print('table', {}, '!! Click to view more')
    print('widget', UIParent, '!! Click to view more')
    geterrorhandler()('An geterrorhandler() call, Click to view more')
    error('A real error, Click to view more', 2)

end

local function Test2()
    Tests()
end

local function Test3()
    Test2()
end

local function Test4()
    Test3()
end

local function Test5()
    Test4()
end

Test5()