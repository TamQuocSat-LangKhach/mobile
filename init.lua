-- SPDX-License-Identifier: GPL-3.0-or-later

Fk:loadTranslationTable(require 'packages/mobile/i18n/en_US', 'en_US')

local prefix = "packages.mobile.pkg."

local mobile_rare = require (prefix.."mobile_rare")
--[[local mobile_sp = require (prefix.."mobile_sp")
local mobile_lxxh = require (prefix.."mobile_lxxh")
local mobile_shiji = require (prefix.."mobile_shiji")
local mobile_re = require (prefix.."mobile_re")
local mobile_test = require (prefix.."mobile_test")
local m_shzl_ex = require (prefix.."m_shzl_ex")
local m_yj_ex = require (prefix.."m_yj_ex")]]--

local mobile_derived = require (prefix.."mobile_derived")

return {
    mobile_rare,
    --[[mobile_sp,
    mobile_lxxh,
    mobile_shiji,
    mobile_re,
    mobile_test,
    m_shzl_ex,
    m_yj_ex,]]--
    mobile_derived,
}
