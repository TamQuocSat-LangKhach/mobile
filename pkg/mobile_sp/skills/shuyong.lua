local shuyong = fk.CreateSkill {
  name = "shuyong",
}

Fk:loadTranslationTable{
  ["shuyong"] = "姝勇",
  [":shuyong"] = "当你使用或打出【杀】时，你可以获得一名其他角色区域内的一张牌；若如此做，其摸一张牌。",

  ["#shuyong-choose"] = "姝勇：你可以获得一名其他角色区域内一张牌，其摸一张牌",

  ["$shuyong1"] = "我的武艺，可是关将军亲传哦！",
  ["$shuyong2"] = "让你看看这招如何！",
}

local shuyongSpec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(shuyong.name) and
      data.card.trueName == "slash" and
      table.find(player.room:getOtherPlayers(player, false), function(p) return not p:isAllNude() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isAllNude()
    end)
    local to = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#shuyong-choose",
        skill_name = shuyong.name,
      }
    )
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = shuyong.name
    local room = player.room
    local to = event:getCostData(self)
    local id = room:askToChooseCard(player, { target = to, flag = "hej", skill_name = skillName })
    room:obtainCard(player, id, false, fk.ReasonPrey, player)
    if not to.dead then
      to:drawCards(1, skillName)
    end
  end,
}

shuyong:addEffect(fk.CardUsing, shuyongSpec)

shuyong:addEffect(fk.CardResponding, shuyongSpec)

return shuyong
