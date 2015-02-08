<?php

# serialize
# int
assert(serialize(0) == 'i:0;');
assert(serialize(100) == 'i:100;');
assert(serialize(-534) == 'i:-534;');
# double
assert(serialize(0.1234567) == 'd:0.1234567;');
assert(serialize(-3.1415926) == 'd:-3.1415926000000001;');
# boolean
assert(serialize(true) == 'b:1;');
assert(serialize(false) == 'b:0;');
# null
assert(serialize(null) == 'N;');
# string
assert(serialize('1') == 's:1:"1";');
assert(serialize('1.0') == 's:3:"1.0";');
assert(serialize('foo') == 's:3:"foo";');
# array key is int
assert(serialize(array(3, 'foo', 'bar')) == 'a:3:{i:0;i:3;i:1;s:3:"foo";i:2;s:3:"bar";}');
assert(serialize(array(1 => 3, 2 => 'foo', 3 => 'bar')) == 'a:3:{i:1;i:3;i:2;s:3:"foo";i:3;s:3:"bar";}');
# array key is boolean
assert(serialize(array(true => 'foo', false => 'bar')) == 'a:2:{i:1;s:3:"foo";i:0;s:3:"bar";}');
# array key is string
assert(serialize(array('foo' => 'bar', 'bar' => 'foo')) == 'a:2:{s:3:"foo";s:3:"bar";s:3:"bar";s:3:"foo";}');
assert(serialize(array('bar' => 'foo', 'foo' => 'bar')) == 'a:2:{s:3:"bar";s:3:"foo";s:3:"foo";s:3:"bar";}');
# array key is string as int
assert(serialize(array('1' => 'foo', '2' => 'bar')) == 'a:2:{i:1;s:3:"foo";i:2;s:3:"bar";}');
assert(serialize(array('1' => 'bar', '2' => 'foo')) == 'a:2:{i:1;s:3:"bar";i:2;s:3:"foo";}');
assert(serialize(array('0' => 'foo', '1' => 'bar')) == 'a:2:{i:0;s:3:"foo";i:1;s:3:"bar";}');
assert(serialize(array('0' => 'bar', '1' => 'foo')) == 'a:2:{i:0;s:3:"bar";i:1;s:3:"foo";}');

# unserialize
# int
assert(0 === unserialize('i:0;'));
assert(100 === unserialize('i:100;'));
assert(-534 === unserialize('i:-534;'));
# double
assert(0.1234567 === unserialize('d:0.1234567;'));
assert(-3.1415926 === unserialize('d:-3.1415926;'));
# boolean
assert(true === unserialize('b:1;'));
assert(false === unserialize('b:0;'));
# null
assert(null === unserialize('N;'));
# string
assert('1' === unserialize('s:1:"1";'));
assert('1.0' === unserialize('s:3:"1.0";'));
assert('foo' === unserialize('s:3:"foo";'));
# table key is int
$t = unserialize('a:3:{i:0;i:3;i:1;s:3:"foo";i:2;s:3:"bar";}');
assert(3 === $t[0]);
assert('foo' === $t[1]);
assert('bar' === $t[2]);
# table key is boolean
$t = unserialize('a:2:{i:0;s:3:"bar";i:1;s:3:"foo";}');
assert('bar' === $t[0]);
assert('foo' === $t[1]);
# table key is string
$t = unserialize('a:2:{s:3:"bar";s:3:"foo";s:3:"foo";s:3:"bar";}');
assert('foo' === $t['bar']);
assert('bar' === $t['foo']);
$t = unserialize('a:2:{s:3:"foo";s:3:"bar";s:3:"bar";s:3:"foo";}');
assert('foo' === $t['bar']);
assert('bar' === $t['foo']);
# table key is string as int
$t = unserialize('a:2:{i:1;s:3:"foo";i:2;s:3:"bar";}');
assert('foo' === $t[1]);
assert('bar' === $t[2]);
$t = unserialize('a:2:{i:1;s:3:"bar";i:2;s:3:"foo";}');
assert('bar' === $t[1]);
assert('foo' === $t[2]);
$t = unserialize('a:2:{i:1;s:3:"bar";i:0;s:3:"foo";}');
assert('foo' === $t[0]);
assert('bar' === $t[1]);
$t = unserialize('a:2:{i:1;s:3:"foo";i:0;s:3:"bar";}');
assert('bar' === $t[0]);
assert('foo' === $t[1]);

?>
