local extension = Package("courage")
extension.extensionName = "mobile"

Fk:loadTranslationTable{
  ["courage"] = "勇包",
  ["mobile"] = "手杀",
}

local wenyang = General(extension, "mobile__wenyang", "wei", 4)
wenyang.subkingdom = "wu"
Fk:loadTranslationTable{
  ["mobile__wenyang"] = "文鸯",
}

local quedi = fk.CreateTriggerSkill{
  name = "quedi",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return
      data.firstTarget and
      target == player and
      player:hasSkill(self.name) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) < (1 + player:getMark("choujue_buff-turn")) and
      table.contains({ "slash", "duel" }, data.card.trueName) and
      player.room:getPlayerById(data.to):isAlive()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {}
    local to = room:getPlayerById(data.to)
    if not to:isKongcheng() then
      table.insert(choices, "quedi-prey")
    end

    if table.find(player:getCardIds(Player.Hand), function(id)
      return Fk:getCardById(id).type == Card.TypeBasic and not player:prohibitDiscard(Fk:getCardById(id))
    end) then
      table.insert(choices, "quedi-offense")
    end

    if #choices > 0 then
      table.insert(choices, 1, "beishui")
      table.insert(choices, "Cancel")

      local choice = room:askForChoice(player, choices, self.name)
      if choice ~= "Cancel" then
        self.cost_data = choice
        return true
      end
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "beishui" then
      room:changeMaxHp(player, -1)
    end

    local to = room:getPlayerById(data.to)
    if self.cost_data == "quedi-prey" or (self.cost_data == "beishui" and not to:isKongcheng()) then
      local cardId = room:askForCardChosen(player, to, "h", self.name)
      room:obtainCard(player, cardId, false, fk.ReasonPrey)
    end
    if self.cost_data == "quedi-offense" or
      (
        self.cost_data == "beishui" and table.find(player:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic and not player:prohibitDiscard(Fk:getCardById(id))
        end)
      )
    then
      room:askForDiscard(player, 1, 1, false, self.name, true, ".|.|.|.|.|basic")
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
Fk:loadTranslationTable{
  ["quedi"] = "却敌",
  [":quedi"] = "每回合限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以选择一项：1.获得其一张手牌；2.弃置一张基本牌，令此【杀】或【决斗】伤害基数+1；背水：减1点体力上限。",
  ["quedi-prey"] = "获得其手牌",
  ["quedi-offense"] = "弃基本牌令此伤害+1",

  ["$quedi1"] = "力摧敌阵，如视天光破云！",
  ["$quedi2"] = "让尔等有命追，无命回！",
}

wenyang:addSkill(quedi)

local chuifeng = fk.CreateViewAsSkill{
  name = "chuifeng",
  anim_type = "offensive",
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2 and player.hp > 0 and player:getMark("chuifeng_nullified-phase") == 0
  end,
  card_filter = function()
    return false
  end,
  view_as = function(self, cards)
    local card = Fk:cloneCard("duel")
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player)
    player.room:loseHp(player, 1, self.name)
  end
}
local chuifengDefence = fk.CreateTriggerSkill{
  name = "#chuifeng_defence",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card and table.contains(data.card.skillNames, chuifeng.name)
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "chuifeng_nullified-phase", 1)
    return true
  end,
}
chuifeng:addAttachedKingdom("wei")
chuifeng:addRelatedSkill(chuifengDefence)
Fk:loadTranslationTable{
  ["chuifeng"] = "椎锋",
  ["#chuifeng_defence"] = "椎锋",
  [":chuifeng"] = "魏势力技，出牌阶段限两次，你可以失去1点体力，并视为使用一张【决斗】。当你受到以此法使用的【决斗】造成的伤害时，防止此伤害，本技能于此阶段内失效。",

  ["$chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
  ["$chuifeng2"] = "登锋履刃，何妨马革裹尸！",
}

wenyang:addSkill(chuifeng)

local chongjian = fk.CreateViewAsSkill{
  name = "chongjian",
  interaction = UI.ComboBox { choices = { "slash", "analeptic" } },
  pattern = "slash,analeptic",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return
    end

    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, useData)
    useData.extra_data = useData.extra_data or {}
    useData.extra_data.chongjianUser = player.id
  end,
  enabled_at_response = function(self, player, cardResponsing)
    return player:hasSkill(self.name) and not cardResponsing
  end,
}
Fk:loadTranslationTable{
  ["chongjian"] = "冲坚",
  [":chongjian"] = "吴势力技，你可以将装备牌当【酒】或无距离限制且无视防具的【杀】使用。当你以此法使用的【杀】对一名角色造成伤害后，你获得其装备区里的X张牌（X为伤害值）。",
  ["#chongjian_buff"] = "冲坚",

  ["$chongjian1"] = "尔等良将，于我不堪一击！",
  ["$chongjian2"] = "此等残兵，破之何其易也！",
}

chongjian:addAttachedKingdom("wu")

local chongjianBuff = fk.CreateTriggerSkill{
  name = "#chongjian_buff",
  mute = true,
  refresh_events = {fk.TargetSpecified, fk.Damaged, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      return (data.extra_data or {}).chongjianNullified
    elseif event == fk.TargetSpecified then
      return table.contains(data.card.skillNames, chongjian.name) and room:getPlayerById(data.to):isAlive()
    else
      if data.to:isAlive() and #data.to:getCardIds(Player.Equip) > 0 then
        local parentUseData = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        return parentUseData and (parentUseData.data[1].extra_data or {}).chongjianUser == player.id
      end

      return false
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUseFinished then
      for key, num in pairs(data.extra_data.chongjianNullified) do
        local p = room:getPlayerById(tonumber(key))
        if p:getMark(fk.MarkArmorNullified) > 0 then
          room:removePlayerMark(p, fk.MarkArmorNullified, num)
        end
      end

      data.chongjianNullified = nil
    elseif event == fk.TargetSpecified then
      room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)

      data.extra_data = data.extra_data or {}
      data.extra_data.chongjianNullified = data.extra_data.chongjianNullified or {}
      data.extra_data.chongjianNullified[tostring(data.to)] = (data.extra_data.chongjianNullified[tostring(data.to)] or 0) + 1
    else
      local equipsNum = #data.to:getCardIds(Player.Equip)
      local num = math.min(equipsNum, data.damage)
      local cards = room:askForCardsChosen(player, data.to, num, num, "e", self.name)

      local pack = Fk:cloneCard("slash")
      pack:addSubcards(cards)
      room:obtainCard(player, pack, true, fk.ReasonPrey)
    end
  end,
}
chongjian:addRelatedSkill(chongjianBuff)

local chongjianUnlimited = fk.CreateTargetModSkill{
  name = "#chongjian_unlimited",
  distance_limit_func = function(self, player, skill, card)
    return table.contains(card.skillNames, chongjian.name) and 999 or 0
  end,
}
chongjian:addRelatedSkill(chongjianUnlimited)
wenyang:addSkill(chongjian)

local mobileChoujue = fk.CreateTriggerSkill{
  name = "mobile__choujue",
  anim_type = "drawcard",
  events = {fk.Deathed},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and data.damage and data.damage.from == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    room:drawCards(player, 2, self.name)
    room:addPlayerMark(player, "choujue_buff-turn", 1)
  end,
}
Fk:loadTranslationTable{
  ["mobile__choujue"] = "仇决",
  [":mobile__choujue"] = "锁定技，当一名角色死亡后，若杀死其的角色为你，你加1点体力上限，摸两张牌，你的“却敌”于本回合内可发动的次数上限+1。",

  ["$mobile__choujue1"] = "血海深仇，便在今日来报！",
  ["$mobile__choujue2"] = "取汝之头，以祭先父！",
}

wenyang:addSkill(mobileChoujue)

return extension
