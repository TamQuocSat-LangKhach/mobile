local zhongyong = fk.CreateSkill{
  name = "m_ex__zhongyong",
}

Fk:loadTranslationTable{
  ["m_ex__zhongyong"] = "忠勇",
  [":m_ex__zhongyong"] = "当你于出牌阶段内使用【杀】结算结束后，若没有目标角色使用【闪】响应过此【杀】，你可以重新获得此【杀】，"..
    "否则你可以选择：1.获得响应此【杀】的【闪】，然后你可以将此【杀】交给另一名其他角色；"..
    "2.将响应此【杀】的【闪】交给另一名其他角色，然后你本阶段使用【杀】的次数上限+1，你本阶段使用的下一张【杀】基础伤害值+1。"..
    "你不能使用本回合通过〖忠勇〗获得的牌。",

  ["$m_ex__zhongyong1"] = "关将军，接刀！",
  ["$m_ex__zhongyong2"] = "青龙三停刀，斩敌万千条！",
}

return zhongyong
