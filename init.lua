local mobile_rare = require "packages/mobile/mobile_rare"
local mobile_sp = require "packages/mobile/mobile_sp"
local mobile_sp2 = require "packages/mobile/mobile_sp2"
local mobile_longxuexuanhuang = require "packages/mobile/mobile_longxuexuanhuang"
local wisdom = require "packages/mobile/wisdom"
local sincerity = require "packages/mobile/sincerity"
local benevolence = require "packages/mobile/benevolence"
local courage = require "packages/mobile/courage"
local strictness = require "packages/mobile/strictness"
local mobile_re = require "packages/mobile/mobile_re"
local mShzlEx = require "packages/mobile/m_shzl_ex"
local mYjEx = require "packages/mobile/m_yj_ex"
local mobileDerived = require "packages/mobile/mobile_derived"

Fk:loadTranslationTable(require 'packages/mobile/i18n/en_US', 'en_US')

return {
  mobile_rare,
  mobile_sp,
  mobile_sp2,
  mobile_longxuexuanhuang,
  wisdom,
  sincerity,
  benevolence,
  courage,
  strictness,
  mobile_re,
  mShzlEx,
  mYjEx,
  mobileDerived,
}
