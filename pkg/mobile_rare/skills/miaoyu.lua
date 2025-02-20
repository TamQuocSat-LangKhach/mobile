local miaoyu = fk.CreateSkill {
  name = "changshi__miaoyu",
}

Fk:loadTranslationTable{
  ["changshi__miaoyu"] = "妙语",
  [":changshi__miaoyu"] = "你可以将至多两张同花色的牌按以下规则使用或打出："..
  "<font color='red'>♥</font>当【桃】，<font color='red'>♦</font>当火【杀】，♣当【闪】，♠当【无懈可击】。"..
  "若你以此法使用或打出了两张：<font color='red'>♥</font>牌，此牌回复基数+1；"..
  "<font color='red'>♦</font>牌，此牌伤害基数+1；黑色牌，你弃置当前回合角色一张牌。",

  ["#changshi__miaoyu"] = "妙语：将至多两张相同花色的牌当对应牌使用或打出，若为两张则执行额外效果",

  ["$changshi__miaoyu1"] = "小伤无碍，安心修养便可。",
}

miaoyu:addEffect("viewas", {
  pattern = "peach,slash,jink,nullification",
  prompt = "#changshi__miaoyu",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    if #selected == 2 then
      return false
    elseif #selected == 1 then
      return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(selected[1]))
    else
      local suit = Fk:getCardById(to_select).suit
      local c
      if suit == Card.Heart then
        c = Fk:cloneCard("peach")
      elseif suit == Card.Diamond then
        c = Fk:cloneCard("fire__slash")
      elseif suit == Card.Club then
        c = Fk:cloneCard("jink")
      elseif suit == Card.Spade then
        c = Fk:cloneCard("nullification")
      else
        return false
      end
      return (Fk.currentResponsePattern == nil and c.skill:canUse(player, c)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(c))
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 0 or #cards > 2 then return end
    local suit = Fk:getCardById(cards[1]).suit
    local c
    if suit == Card.Heart then
      c = Fk:cloneCard("peach")
    elseif suit == Card.Diamond then
      c = Fk:cloneCard("fire__slash")
    elseif suit == Card.Club then
      c = Fk:cloneCard("jink")
    elseif suit == Card.Spade then
      c = Fk:cloneCard("nullification")
    else
      return nil
    end
    c.skillName = miaoyu.name
    c:addSubcards(cards)
    return c
  end,
  before_use = function(self, player, use)
    local num = #use.card.subcards
    if num == 2 then
      local suit = Fk:getCardById(use.card.subcards[1]).suit
      if suit == Card.Diamond then
        use.additionalDamage = (use.additionalDamage or 0) + 1
      elseif suit == Card.Heart then
        use.additionalRecover = (use.additionalRecover or 0) + 1
      end
    end
  end,
})

local miaoyu_spec = {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      table.contains(data.card.skillNames, "miaoyu") and #data.card.subcards == 2 and
      Fk:getCardById(data.card.subcards[1]).color == Card.Black and
      not player.dead and not player.room.current.dead and not player.room.current:isNude()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = room:askToChooseCard(player, {
      target = room.current,
      flag = "he",
      skill_name = miaoyu.name,
    })
    room:throwCard(card, miaoyu.name, room.current, player)
  end,
}

miaoyu:addEffect(fk.CardUseFinished, miaoyu_spec)
miaoyu:addEffect(fk.CardRespondFinished, miaoyu_spec)

return miaoyu
