#!/usr/bin/ruby

require 'rubygems'
require 'rbridge'
require 'date'

sync = RBridge.new('lists', 'localhost', 9000, false)

# synchronous method calls
p sync.sort(["Take Five", "All of Me", "'round Midnight", "Cousin Mary"])
p sync.erl(<<-ERL
 F = fun(X) -> string:to_upper(X) end,
 lists:map(F, ["Naima", "So What", "Bluebird"]). 
 ERL
)

["string", "10", "1.234", "atom", "{this,is,a,tuple}", 
  "[this,is,a,list]", "<<\"binary\",10,13>>", "<<1,2,3,4,5>>"
].each do |expr|
  val = sync.erl(expr + ".")
  puts "#{val.inspect} -> #{val.class}"
end


# async process calls
async = RBridge.new(nil, 'localhost', 9000, true)
puts "Before call: #{DateTime.now}"
thr = async.erl(%q[
  {ok, Id} = http:request(get, {"http://www.allmusic.com", []}, [], [{sync,false}]),
  receive {http, {Id, {Status, Headers, Body}}} ->
    Status
  end.
],
 Proc.new {|val| puts "Block called at #{DateTime.now} with value:\n #{val.inspect}"}
)
puts "After call: #{DateTime.now}"
thr.join

# monkey patch for :erl method
class RBridge
  alias old_erl erl
  def erl(command, &block)
    if block_given?
      old_erl(command, Proc.new(&block))
    else
      old_erl(command)
    end
  end
end

thr = async.erl("1+2.") do |val|
  puts "Block called with value #{val}"
end
thr.join

