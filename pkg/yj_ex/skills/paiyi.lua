local paiyi = fk.CreateSkill {
  name = "m_ex__paiyi",
}

Fk:loadTranslationTable{
  ["m_ex__paiyi"] = "排异",
  [":m_ex__paiyi"] = "出牌阶段限一次，你可以移去一张“权”，令一名角色摸两张牌。若该角色的手牌数大于你，你对其造成1点伤害。",
  ["#m_ex__paiyi-active"] = "发动排异，选择一张“权”牌置入弃牌堆并选择一名角色，令其摸两张牌",
  ["$m_ex__paiyi1"] = "坏吾大计者，罪死不赦！",
  ["$m_ex__paiyi2"] = "攻讦此子，祸咎已除！",
}

paiyi:addEffect("active", {
  name = "m_ex__paiyi",
  anim_type = "control",
  prompt = "#m_ex__paiyi-active",
  max_phase_use_time = 1,
  card_num = 1,
  target_num = 1,
  expand_pile = "m_ex__zhonghui_power",
  can_use = function(self, player)
    return #player:getPile("m_ex__zhonghui_power") > 0 and player:usedSkillTimes(paiyi.name, Player.HistoryPhase) == 0
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "m_ex__zhonghui_power"
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCards({
      from = player.id,
      ids = effect.cards,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = paiyi.name,
    })
    if not target.dead then
      room:drawCards(target, 2, paiyi.name)
    end
    if not player.dead and not target.dead and target:getHandcardNum() > player:getHandcardNum() then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = paiyi.name,
      }
    end
  end,
})

return paiyi
