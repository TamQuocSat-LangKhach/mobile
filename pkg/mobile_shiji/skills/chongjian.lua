local chongjian = fk.CreateSkill {
  name = "chongjian",
  tags = { Skill.AttachedKingdom },
  attached_kingdom = {"wu"},
}

Fk:loadTranslationTable{
  ["chongjian"] = "冲坚",
  [":chongjian"] = "吴势力技，你可以将一张装备牌当【酒】或无距离限制且无视防具的任意一种【杀】使用。当你以此法使用的【杀】对一名角色造成伤害后，"..
  "你获得其装备区里的X张牌（X为伤害值）。",

  ["#chongjian"] = "冲坚：将装备牌当【酒】，或无距离限制且无视防具的【杀】使用",

  ["$chongjian1"] = "尔等良将，于我不堪一击！",
  ["$chongjian2"] = "此等残兵，破之何其易也！",
}

chongjian:addEffect("viewas", {
  prompt = "#chongjian",
  pattern = "slash,analeptic",
  interaction = function(self, player)
    local names = {}
    for name, _ in pairs(Fk.all_card_types) do
      local card = Fk:cloneCard(name)
      if not card.is_derived and not table.contains(Fk:currentRoom().disabled_packs, card.package.name)
        and (card.name == "analeptic" or card.trueName == "slash")
        and ((Fk.currentResponsePattern == nil and player:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        table.insertIfNeed(names, name)
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = chongjian.name
    return card
  end,
  before_use = function(self, player, use)
    if use.card.name == "analeptic" then
      use.extra_data = use.extra_data or {}
      use.extra_data.chongjian = player
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})
chongjian:addEffect(fk.Damage, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    if not (player.dead or data.to.dead) and #data.to:getCardIds("e") > 0 then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
      return use_event and (use_event.data.extra_data or {}).chongjian == player
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local num = math.min(#data.to:getCardIds("e"), data.damage)
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = num,
      max = num,
      flag = "e",
      skill_name = chongjian.name,
    })
    room:obtainCard(player, cards, true, fk.ReasonPrey, player, chongjian.name)
  end,
})
chongjian:addEffect(fk.TargetSpecified, {
  can_refresh = function (self, event, target, player, data)
    return (data.extra_data or {}).chongjian == player and not data.to.dead
  end,
  on_refresh = function (self, event, target, player, data)
    data.to:addQinggangTag(data)
  end,
})
chongjian:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return card and table.contains(card.skillNames, chongjian.name)
  end,
})

return chongjian
