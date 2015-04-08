package.path = './container/?.lua;' .. package.path

function print_r(t)
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(k, '=')
            print_r(v)
        else
            print(k, '=', v)
        end
    end
end

local php = require 'serialize'

local ps = php:new()

-- serialize
-- int
assert(ps:serialize(0) == 'i:0;')
assert(ps:serialize(100) == 'i:100;')
assert(ps:serialize(-534) == 'i:-534;')
-- double
assert(ps:serialize(0.1234567) == 'd:0.1234567;')
assert(ps:serialize(-3.1415926) == 'd:-3.1415926;')
-- boolean
assert(ps:serialize(true) == 'b:1;')
assert(ps:serialize(false) == 'b:0;')
-- nil
assert(ps:serialize(nil) == 'N;')
-- string
assert(ps:serialize('1') == 's:1:"1";')
assert(ps:serialize('1.0') == 's:3:"1.0";')
assert(ps:serialize('foo') == 's:3:"foo";')
-- table key is int
assert(ps:serialize({3, 'foo', 'bar'}) == 'a:3:{i:0;i:3;i:1;s:3:"foo";i:2;s:3:"bar";}')
assert(ps:serialize({[1] = 3, [2] = 'foo', [3] = 'bar'}) == 'a:3:{i:0;i:3;i:1;s:3:"foo";i:2;s:3:"bar";}')
-- table key is boolean
assert(ps:serialize({[true] = 'foo', [false] = 'bar'}) == 'a:2:{i:0;s:3:"bar";i:1;s:3:"foo";}')
-- table key is string
assert(ps:serialize({['foo'] = 'bar', ['bar'] = 'foo'}) == 'a:2:{s:3:"bar";s:3:"foo";s:3:"foo";s:3:"bar";}')
assert(ps:serialize({['bar'] = 'foo', ['foo'] = 'bar'}) == 'a:2:{s:3:"foo";s:3:"bar";s:3:"bar";s:3:"foo";}')
-- table key is string as int
assert(ps:serialize({['1'] = 'foo', ['2'] = 'bar'}) == 'a:2:{i:1;s:3:"foo";i:2;s:3:"bar";}')
assert(ps:serialize({['1'] = 'bar', ['2'] = 'foo'}) == 'a:2:{i:1;s:3:"bar";i:2;s:3:"foo";}')
assert(ps:serialize({['0'] = 'foo', ['1'] = 'bar'}) == 'a:2:{i:1;s:3:"bar";i:0;s:3:"foo";}')
assert(ps:serialize({['0'] = 'bar', ['1'] = 'foo'}) == 'a:2:{i:1;s:3:"foo";i:0;s:3:"bar";}')

-- unserialize
-- int
assert(0 == ps:unserialize('i:0;'))
assert(100 == ps:unserialize('i:100;'))
assert(-534 == ps:unserialize('i:-534;'))
-- double
assert(0.1234567 == ps:unserialize('d:0.1234567;'))
assert(-3.1415926 == ps:unserialize('d:-3.1415926;'))
-- boolean
assert(true == ps:unserialize('b:1;'))
assert(false == ps:unserialize('b:0;'))
-- nil
assert(nil == ps:unserialize('N;'))
-- string
assert('1' == ps:unserialize('s:1:"1";'))
assert('1.0' == ps:unserialize('s:3:"1.0";'))
assert('foo' == ps:unserialize('s:3:"foo";'))
-- table key is int
local t = ps:unserialize('a:3:{i:0;i:3;i:1;s:3:"foo";i:2;s:3:"bar";}')
assert(3 == t[1])
assert('foo' == t[2])
assert('bar' == t[3])
-- table key is boolean
local t = ps:unserialize('a:2:{i:0;s:3:"bar";i:1;s:3:"foo";}')
assert('bar' == t[1])
assert('foo' == t[2])
-- table key is string
local t = ps:unserialize('a:2:{s:3:"bar";s:3:"foo";s:3:"foo";s:3:"bar";}')
assert('foo' == t['bar'])
assert('bar' == t['foo'])
local t = ps:unserialize('a:2:{s:3:"foo";s:3:"bar";s:3:"bar";s:3:"foo";}')
assert('foo' == t['bar'])
assert('bar' == t['foo'])
-- table key is string as int
local t = ps:unserialize('a:2:{i:1;s:3:"foo";i:2;s:3:"bar";}')
assert('foo' == t[2])
assert('bar' == t[3])
local t = ps:unserialize('a:2:{i:1;s:3:"bar";i:2;s:3:"foo";}')
assert('bar' == t[2])
assert('foo' == t[3])
local t = ps:unserialize('a:2:{i:1;s:3:"bar";i:0;s:3:"foo";}')
assert('foo' == t[1])
assert('bar' == t[2])
local t = ps:unserialize('a:2:{i:1;s:3:"foo";i:0;s:3:"bar";}')
assert('bar' == t[1])
assert('foo' == t[2])

local s = "O:36:\"nsp_mq_core_command_impl_RequestImpl\":3:{s:8:\"contexts\";a:6:{s:8:\"nsp_addr\";s:14:\"221.226.48.130\";s:9:\"nsp_stack\";s:104:\"bH9ygMooTAIM98L8QAlSJ7m2/AQ1ZgcQxoISegpiCTkkGdIcbxPEgR+a8WN4f/HfUv00vvO5FWIproF6ZishbkG9E3eu7bsCNz76kxlg\";s:7:\"nsp_tpk\";s:32:\"845ced60c42a7f1d5699c0e531d7e654\";s:7:\"nsp_cid\";s:32:\"364a97f2f79009cc9e993d2fb6dee45a\";s:7:\"nsp_uid\";d:900086000000000362;s:7:\"nsp_app\";i:60992;}s:10:\"properties\";a:9:{s:3:\"svc\";s:29:\"HispaceStore.store.getAppdown\";s:2:\"id\";s:36:\"c81f07a7-cb90-4762-ae55-257616c38593\";s:3:\"sid\";s:49:\"TSeGsmF9UV7XmDNrR0by7WIBdeLeOTOZPCPJOrJ+IvxKzzgzZ\";s:7:\"replyto\";s:31:\"/temp-queue/50996-1371524737733\";s:4:\"path\";s:78:\"OpenOther.Delegate.HispaceStore_store_getAppdown|HispaceStore.store.getAppdown\";s:4:\"type\";s:7:\"request\";s:5:\"reqid\";s:36:\"c81f07a7-cb90-4762-ae55-257616c38593\";s:3:\"app\";i:60992;s:11:\"destination\";s:25:\"/queue/HispaceStore.store\";}s:6:\"params\";a:5:{i:0;N;i:1;s:10:\"2013-07-01\";i:2;s:10:\"2013-07-05\";i:3;s:1:\"0\";i:4;s:1:\"1\";}}"
print(s)
print(ps:serialize(ps:unserialize(s)))
print_r(ps:unserialize(s))

local s = "O:36:\"nsp_mq_core_command_impl_RequestImpl\":3:{s:8:\"contexts\";a:6:{s:8:\"nsp_addr\";s:14:\"221.226.48.130\";s:9:\"nsp_stack\";s:104:\"bH9ygMooTAIM98L8QAlSJ7m2/AQ1ZgcQxoISegpiCTkkGdIcbxPEgR+a8WN4f/HfUv00vvO5FWIproF6ZishbkG9E3eu7bsCNz76kxlg\";s:7:\"nsp_tpk\";s:32:\"845ced60c42a7f1d5699c0e531d7e654\";s:7:\"nsp_cid\";s:32:\"364a97f2f79009cc9e993d2fb6dee45a\";s:7:\"nsp_uid\";d:900086000000000362;s:7:\"nsp_app\";i:60992;}s:10:\"properties\";a:9:{s:3:\"svc\";s:29:\"HispaceStore.store.getAppdown\";s:2:\"id\";s:36:\"9fa44959-c6ab-43f3-abc7-7e8b3a3c32c6\";s:3:\"sid\";s:49:\"TSeGsmF9UV7XmDNrR0by7WIBdeLeOTOZPCPJOrJ+IvxKzzgzZ\";s:7:\"replyto\";s:68:\"/temp-queue/50996-c1805d32-679d-4846-b5d8-fa6ff90e2b41-1373005969062\";s:4:\"path\";s:78:\"OpenOther.Delegate.HispaceStore_store_getAppdown|HispaceStore.store.getAppdown\";s:4:\"type\";s:7:\"request\";s:5:\"reqid\";s:36:\"9fa44959-c6ab-43f3-abc7-7e8b3a3c32c6\";s:3:\"app\";i:60992;s:11:\"destination\";s:25:\"/queue/HispaceStore.store\";}s:6:\"params\";a:5:{i:0;N;i:1;N;i:2;N;i:3;N;i:4;N;}}"
print(s)
print(ps:serialize(ps:unserialize(s)))
print_r(ps:unserialize(s))

local s = "O:36:\"nsp_mq_core_command_impl_RequestImpl\":3:{s:8:\"contexts\";a:1:{s:8:\"nsp_addr\";s:9:\"127.0.0.1\";}s:10:\"properties\";a:6:{s:3:\"svc\";s:16:\"nsp.foo.sayHello\";s:2:\"id\";s:36:\"6ad6524f-4ede-4cfa-8884-c5f532f1c9a2\";s:7:\"replyto\";s:38:\"/temp-queue/10.46.79.158_1373282773578\";s:4:\"type\";s:7:\"request\";s:5:\"reqid\";s:32:\"5N25B7GR4ZQ29JUPGRIL8GFOM80Q245I\";s:11:\"destination\";s:14:\"/queue/nsp.foo\";}s:6:\"params\";a:1:{i:0;s:5:\"hello\";}}"
print(s)
print(ps:serialize(ps:unserialize(s)))
print_r(ps:unserialize(s))
