<p align="center">
    <img style="float: left" src="https://github.com/user-attachments/assets/8d0131a4-1061-42b2-a3ab-0409113afbcd" width="25%" height="25%">
    <img style="float: left" src="https://github.com/user-attachments/assets/d3852943-d71e-4c3c-83c6-9fa6d261d178" width="50%" height="50%">
</p>

luafixes.lua
```lua
-- id()
myTable = {}
id(myTable) -- 27FC3608

-- table.prepend
table1 = {"foo", "bar"}
table2 = {"foobar"}
table.prepend(table1, table2) -- {"foo", "bar", "foobar"}
```
print.lua
```lua
-- print()
print("Foo: ", 42) -- Foo: 42
print("Foo: ", "Bar: ", 42) -- Foo: Bar: 42
print("Foo: ", table1) -- Foo: 27FC3608
```
Debug.lua
```lua
-- Debug:unpack()
function test(...)
  Debug:unpack(arg) -- "foo bar"
  Debug:unpack(arg, ", ") -- "foo, bar"
end
test("foo", "bar")

and more..
```

Some fun things,

```lua
MyObject = {}
function MyObject:load(...)
  if event == "ADDON_LOADED" then
    if arg[1] == "MyAddon" then
      -- etc
    end
  end
end

Frame:SetScript("OnEvent", bind(self, MyObject.load))
```
