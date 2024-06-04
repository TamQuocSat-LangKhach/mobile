local mobile_rare = require "packages/mobile/mobile_rare"
local mobile_sp = require "packages/mobile/mobile_sp"
local mobile_test = require "packages/mobile/mobile_test"
local wisdom = require "packages/mobile/wisdom"
local sincerity = require "packages/mobile/sincerity"
local benevolence = require "packages/mobile/benevolence"
local courage = require "packages/mobile/courage"
local strictness = require "packages/mobile/strictness"
local mShzlEx = require "packages/mobile/m_shzl_ex"
local mYjEx = require "packages/mobile/m_yj_ex"
local mobileDerived = require "packages/mobile/mobile_derived"

Fk:loadTranslationTable(require 'packages/mobile/i18n/en_US', 'en_US')

return {
  mobile_rare,
  mobile_sp,
  mobile_test,
  wisdom,
  sincerity,
  benevolence,
  courage,
  strictness,
  mShzlEx,
  mYjEx,
  mobileDerived,
}
