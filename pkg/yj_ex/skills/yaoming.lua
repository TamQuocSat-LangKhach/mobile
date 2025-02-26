local yaoming = fk.CreateSkill{
  name = "m_ex__yaoming",
}

Fk:loadTranslationTable{
  ---FIXME: 邀名不是蓄力技，等谋诸葛瑾正式上限再测，先按蓄力技处理
  ["m_ex__yaoming"] = "邀名",
  [":m_ex__yaoming"] = "蓄力技（2/4），出牌阶段或当你受到伤害后，你可以减1点“蓄力”值并选择一项：1.弃置手牌数不小于你的一名其他角色的一张牌；"..
  "2.令手牌数不大于你的一名角色摸一张牌。若与你上次选择的选项不同，你获得1点“蓄力”值，并清除已记录的选项。每当你受到1点伤害后，你获得1点“蓄力”值。",

  ["#m_ex__yaoming"] = "邀名：你可以减1点“蓄力”值，弃置一名角色一张牌或令其摸一张牌",
  ["m_ex__yaoming_throw"] = "弃置手牌数不小于你的其他角色一张牌",
  ["m_ex__yaoming_draw"] = "令手牌数不大于你的一名角色摸一张牌",
  ["@m_ex__yaoming"] = "邀名",
  ["m_ex__yaoming_throw_mark"] = "弃牌",
  ["m_ex__yaoming_draw_mark"] = "摸牌",
  ["#m_ex__yaoming-invoke"] = "你可以发动“邀名”",
  ["#m_ex__yaoming_trigger"] = "邀名",

  ["$m_ex__yaoming1"] = "山不让纤介，而成其危；海不辞丰盈，而成其邃。",
  ["$m_ex__yaoming2"] = "取上方可得中，取下则无所得矣。",
}

return yaoming
