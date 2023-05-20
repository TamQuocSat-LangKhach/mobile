local courage = require "packages/mobile/courage"
local wisdom = require "packages/mobile/wisdom"
local mobileSP = require "packages/mobile/mobile_sp"
local mobileDerived = require "packages/mobile/mobile_derived"

Fk:loadTranslationTable{
  ["mobile"] = "手杀",
}

return {
  wisdom,
  courage,
  mobileSP,
  mobileDerived,
}
