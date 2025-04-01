local tongqu = fk.CreateSkill {
  name = "tongqu",
}

Fk:loadTranslationTable{
  ["tongqu"] = "通渠",
  [":tongqu"] = "游戏开始时，你获得一枚“渠”标记；准备阶段，你可以失去1点体力令一名没有“渠”标记的角色获得“渠”标记。有“渠”的角色摸牌阶段额外摸一张牌，"..
  "然后将一张牌交给另一名有“渠”的角色或弃置一张牌，若以此法给出的是装备牌则其使用之。有“渠”的角色进入濒死状态时移除其“渠”。",

  ["@@tongqu"] = "通渠",
  ["#tongqu-choose"] = "通渠：你可以失去1点体力，令一名角色获得“渠”标记",
  ["#tongqu-give"] = "通渠：将一张牌交给一名有“渠”的角色，或弃置一张牌",

  ["$tongqu1"] = "兴凿修渠，依水屯军！",
  ["$tongqu2"] = "开渠疏道，以备军实！",
}

tongqu:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tongqu.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tongqu", 1)
  end,
})

tongqu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(tongqu.name) and
      player.phase == Player.Start and
      table.find(player.room.alive_players, function(p) return p:getMark("@@tongqu") == 0 end)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p) return p:getMark("@@tongqu") == 0 end)
    local to = player.room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#tongqu-choose",
        skill_name = tongqu.name,
      }
    )
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    room:setPlayerMark(event:getCostData(self), "@@tongqu", 1)
  end,
})

local tongquDelayCanTrigger = function(self, event, target, player, data)
  return target == player and player:getMark("@@tongqu") > 0
end

tongqu:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  anim_type = "drawcard",
  can_trigger = tongquDelayCanTrigger,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

tongqu:addEffect(fk.AfterDrawNCards, {
  is_delay_effect = true,
  mute = true,
  can_trigger = tongquDelayCanTrigger,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not player:isNude() then
      local success, dat = room:askToUseActiveSkill(
        player,
        {
          skill_name = "tongqu_active",
          prompt = "#tongqu-give",
          cancelable = false,
        }
      )
      if success and dat then
        if #dat.targets == 1 then
          local to = dat.targets[1]
          local id = dat.cards[1]
          room:obtainCard(to, id, false, fk.ReasonGive, player)

          local card = Fk:getCardById(id)
          if
            room:getCardOwner(id) == to and
            room:getCardArea(id) == Card.PlayerHand and
            card.type == Card.TypeEquip and
            not to:isProhibited(to, card)
          then
            room:useCard({
              from = to,
              tos = { to },
              card = card,
            })
          end
        else
          room:throwCard(dat.cards, tongqu.name, player, player)
        end
      end
    end
  end,
})

tongqu:addEffect(fk.EnterDying, {
  anim_type = "negative",
  can_trigger = tongquDelayCanTrigger,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@tongqu", 0)
  end,
})

return tongqu
