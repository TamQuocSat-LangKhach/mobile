local sidi = fk.CreateSkill {
  name = "m_ex__sidi",
}

Fk:loadTranslationTable{
  ["m_ex__sidi"] = "司敌",
  [":m_ex__sidi"] = "当你使用除延时锦囊以外的牌结算结束后，可以选择一名还未指定“司敌”目标的其他角色，并为其指定一名“司敌”目标角色（均不可见）。"..
    "其使用的第一张除延时锦囊以外的牌仅指定“司敌”目标为唯一角色时（否则清除你为其指定的“司敌”目标角色），"..
    "你根据以下情况执行效果：若目标为你，你摸一张牌；若目标不为你，你选择："..
    "1.取消之，然后若此时场上没有任何角色处于濒死状态，你对其造成1点伤害；2.你摸两张牌。然后清除你为其指定的“司敌”目标角色。",

  ["#m_ex__sidi-choose"] = "你可发动司敌，选择1名角色，为其指定司敌目标",
  ["#m_ex__sidi-choose2"] = "司敌：为%dest指定司敌目标，若正确，可发动响应效果",
  ["#m_ex__sidi-choice"] = "司敌：选择取消%dest使用的%arg，或摸两张牌",
  ["m_ex__sidi_negate"] = "取消此牌",
  ["m_ex__sidi_negate_and_damage"] = "取消此牌并对使用者造成伤害",
  ["@@m_ex__sidi"] = "司敌",

  ["$m_ex__sidi1"] = "司敌之动，先发而制。",
  ["$m_ex__sidi2"] = "料敌之行，伏兵灭之。",
}

return sidi
