local zongxuan = fk.CreateSkill {
  name = "m_ex__zongxuan",
}

Fk:loadTranslationTable{
  ["m_ex__zongxuan"] = "纵玄",
  [":m_ex__zongxuan"] = "出牌阶段限一次，你可以摸一张牌，然后将一张牌置于牌堆顶；当你的牌因弃置而置入弃牌堆时，你可以将其中任意张牌置于牌堆顶。",

  ["#m_ex__zongxuan-active"] = "纵玄：你可以摸一张牌，然后将一张牌置于牌堆顶",
  ["#m_ex__zongxuan-put"] = "纵玄：将一张牌置于牌堆顶",

  ["$m_ex__zongxuan1"] = "",
  ["$m_ex__zongxuan2"] = "",
}

zongxuan:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#m_ex__zongxuan-active",
  max_phase_use_time = 1,
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, use)
    local player = use.from
    player:drawCards(1, zongxuan.name)
    if player:isNude() then return end
    local card = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      include_equip = false,
      skill_name = zongxuan.name,
      cancelable = false,
      prompt = "#m_ex__zongxuan-put",
    })
    room:moveCardTo(card, Card.DrawPile, nil, fk.ReasonPut, zongxuan.name, nil, false, player)
  end,
})

zongxuan:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(zongxuan.name) then
      local room = player.room
      local cards = {}
      for _, move in ipairs(data) do
        if move.from == player and move.toArea == Card.DiscardPile and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
              if room:getCardArea(info.cardId) == Card.DiscardPile then
                table.insertIfNeed(cards, info.cardId)
              end
            end
          end
        end
      end
      cards = room.logic:moveCardsHoldingAreaCheck(cards)
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    if #cards > 1 then
      cards = table.reverse(room:askToGuanxing(player, {
        cards = cards,
        top_limit = {1, #cards},
        bottom_limit = nil,
        skill_name = zongxuan.name,
        skip = true,
        area_names = {"Top", "zongxuanNoput"}
      }).top)
    end
    room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, zongxuan.name, nil, false, player)
  end,
})

return zongxuan
