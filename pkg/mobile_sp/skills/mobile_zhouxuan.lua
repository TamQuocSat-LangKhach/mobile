local mobileZhouxuan = fk.CreateSkill {
  name = "mobile__zhouxuan",
}

Fk:loadTranslationTable{
  ["mobile__zhouxuan"] = "周旋",
  [":mobile__zhouxuan"] = "出牌阶段限一次，你可以弃置一张牌，选择一名其他角色并选择一种非基本牌的类型或一种基本牌的牌名。若该角色之后"..
  "使用或打出的第一张牌与你的选择相同，你观看牌堆顶的三张牌，并分配给任意角色。",

  ["#mobile__zhouxuan"] = "周旋：弃置一张牌，猜测一名角色使用或打出下一张牌的牌名/类别",
  ["#mobile__zhouxuan_trigger"] = "周旋",
  ["#mobile__zhouxuan-give"] = "周旋：你可以将这些牌任意分配，点“取消”自己保留",

  ["$mobile__zhouxuan1"] = "孰为虎？孰为鹰？于吾都如棋子。",
  ["$mobile__zhouxuan2"] = "群雄逐鹿之际，唯有洞明时势方有所成。",
}

mobileZhouxuan:addEffect("active", {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#mobile__zhouxuan",
  interaction = function()
    local names = { "trick", "equip" }
    table.insertTable(names, Fk:getAllCardNames("b", true))
    return UI.ComboBox { choices = names }
  end,
  can_use = function (self, player)
    return player:usedSkillTimes(mobileZhouxuan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function (self, room, effect)
    ---@type string
    local skillName = mobileZhouxuan.name
    local player = effect.from
    room:addTableMark(player, skillName, { effect.tos[1].id, self.interaction.data })
    room:throwCard(effect.cards, skillName, player, player)
  end,
})

local mobileZhouxuanDelaySpec = {
  is_delay_effect = true,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return table.find(player:getTableMark(mobileZhouxuan.name), function(m) return m[1] == target.id end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = mobileZhouxuan.name
    local room = player.room
    local mark = player:getTableMark(skillName)
    local can_invoke
    for i = #mark, 1, -1 do
      if mark[i][1] == target.id then
        if mark[i][2] == data.card.trueName or mark[i][2] == data.card:getTypeString() then
          can_invoke = true
        end
        table.remove(mark, i)
      end
    end
    room:setPlayerMark(player, skillName, mark)
    if can_invoke then
      player:broadcastSkillInvoke(skillName)
      room:notifySkillInvoked(player, skillName, "drawcard")
      local cards = room:getNCards(3)
      room:askToYiji(
        player,
        {
          cards = cards,
          min_num = 3,
          max_num = 3,
          skill_name = skillName,
          expand_pile = cards,
        }
      )
    end
  end,
}

mobileZhouxuan:addEffect(fk.CardUsing, mobileZhouxuanDelaySpec)

mobileZhouxuan:addEffect(fk.CardResponding, mobileZhouxuanDelaySpec)

return mobileZhouxuan
