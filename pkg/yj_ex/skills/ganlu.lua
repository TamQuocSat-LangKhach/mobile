local ganlu = fk.CreateSkill {
  name = "m_ex__ganlu",
}

local U = require "packages/utility/utility"

Fk:loadTranslationTable{
  ["m_ex__ganlu"] = "甘露",
  [":m_ex__ganlu"] = "出牌阶段限一次，你可以选择两名装备区里的牌数之差不大于你已损失的体力值的角色，交换他们装备区里的牌；"..
    "若你选择的角色中含有你，则不受牌数之差的限制。",

  ["#m_ex__ganlu-active"] = "甘露：令两名装备区里的牌数之差不大于%arg的角色交换装备区里的牌，若选择自己则此无限制",

  ["$m_ex__ganlu1"] = "玄德实乃佳婿呀。",
  ["$m_ex__ganlu2"] = "好一个郎才女貌，真是天作之合啊。",
}

ganlu:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#m_ex__ganlu-active:::" .. tostring(player:getLostHp())
  end,
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return #to_select.player_cards[Player.Equip] > 0
    elseif #selected == 1 then
      return (
        selected[1] == player or
        to_select == player or
        math.abs(#to_select.player_cards[Player.Equip] - #selected[1].player_cards[Player.Equip]) <= player:getLostHp()
      )
    end
    return false
  end,
  on_use = function(self, room, effect)
    U.swapCards(
      room,
      effect.from,
      effect.tos[1],
      effect.tos[2],
      effect.tos[1]:getCardIds(Player.Equip),
      effect.tos[2]:getCardIds(Player.Equip),
      ganlu.name,
      Player.Equip
    )
  end,
})

return ganlu
