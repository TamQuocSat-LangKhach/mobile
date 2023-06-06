local courage = require "packages/mobile/courage"
local wisdom = require "packages/mobile/wisdom"
local mobileSP = require "packages/mobile/mobile_sp"
local mobileDerived = require "packages/mobile/mobile_derived"
local sincerity = require "packages/mobile/sincerity"
local mYjEx = require "packages/mobile/m_yj_ex"

Fk:loadTranslationTable{
  ["mobile"] = "手杀",
}

return {
  wisdom,
  courage,
  sincerity,
  mobileSP,
  mYjEx,
  mobileDerived,
}
