local skill = fk.CreateSkill {
  name = "#ex_eight_diagram_skill",
}

Fk:loadTranslationTable{
  ["#ex_eight_diagram_skill"] = "先天八卦阵",
}

local eight_diagram_on_use = function (self, event, target, player, data)
    local room = player.room
    local judgeData = {
      who = player,
      reason = self.name,
      pattern = ".|.|club,heart,diamond",
    }
    room:judge(judgeData)

    if judgeData.card.suit ~= Card.Spade then
      if event:isInstanceOf(fk.AskForCardUse) then
        data.result = {
          from = player,
          card = Fk:cloneCard("jink"),
          tos = {},
        }
        data.result.card.skillName = "ex_eight_diagram"

        if data.eventData then
          data.result.toCard = data.eventData.toCard
          data.result.responseToEvent = data.eventData.responseToEvent
        end
      else
        data.result = Fk:cloneCard("jink")
        data.result.skillName = "ex_eight_diagram"
      end

      return true
    end
  end
skill:addEffect(fk.AskForCardUse, {
  attached_equip = "ex_eight_diagram",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      not player:prohibitUse(Fk:cloneCard("jink"))
  end,
  on_use = eight_diagram_on_use,
})
skill:addEffect(fk.AskForCardResponse, {
  attached_equip = "ex_eight_diagram",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      not player:prohibitResponse(Fk:cloneCard("jink"))
  end,
  on_use = eight_diagram_on_use,
})

skill:addTest(function(room, me)
  local eight_diagram = room:printCard("ex_eight_diagram")
  local comp2 = room.players[2]

  FkTest.setNextReplies(me, { "1" })
  FkTest.runInRoom(function()
    room:useCard {
      from = me,
      tos = { me },
      card = eight_diagram,
    }
    room:moveCardTo(room:printCard("slash", Card.Heart), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(me.hp, 4)
  FkTest.setNextReplies(me, { "1", "1", "" })
  FkTest.runInRoom(function()
    room:moveCardTo(room:printCard("slash", Card.Diamond), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("archery_attack"),
    }
    room:moveCardTo(room:printCard("slash", Card.Spade), Card.DrawPile)
    room:useCard {
      from = comp2,
      tos = { me },
      card = Fk:cloneCard("slash"),
    }
  end)
  lu.assertEquals(me.hp, 3)
end)

return skill
