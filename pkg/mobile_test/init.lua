local extension = Package:new("mobile_test")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_test/skills")

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
}

General:new(extension, "m_friend__cuijun", "qun", 3):addSkills { "shunyi", "biwei", "cuijun__gongli" }
Fk:loadTranslationTable{
  ["m_friend__cuijun"] = "友崔钧",
  ["#m_friend__cuijun"] = "日奋金丝",
  --["illustrator:m_friend__cuijun"] = "",

  ["~m_friend__cuijun"] = "与君等交何其之快，只惜无再聚之日矣……",
}

General:new(extension, "m_friend__shitao", "qun", 3):addSkills { "qinying", "lunxiong", "shitao__gongli" }
Fk:loadTranslationTable{
  ["m_friend__shitao"] = "友石韬",
  ["#m_friend__shitao"] = "月堕窠臼",
  --["illustrator:m_friend__shitao"] = "",

  ["~m_friend__shitao"] = "空有一腔热血，却是报国无门……",
}

General:new(extension, "wuke", "wu", 3, 3, General.Female):addSkills { "anda", "zhuguo" }
Fk:loadTranslationTable{
  ["wuke"] = "吴珂",
  ["#wuke"] = "",
  --["illustrator:wuke"] = "",

  ["~wuke"] = "诸君竭辅仲谋，万事务以江东为虑。",
}

General:new(extension, "mobile__xiahoushang", "wei", 4):addSkills { "tanfeng" }
Fk:loadTranslationTable{
  ["mobile__xiahoushang"] = "夏侯尚",
  ["#mobile__xiahoushang"] = "魏胤前驱",
  --["illustrator:mobile__xiahoushang"] = "",

  ["~mobile__xiahoushang"] = "",
}

General:new(extension, "mobile__guanyinping", "shu", 3, 4, General.Female):addSkills { "mobile__xuehen", "mobile__huxiao", "mobile__wuji" }
Fk:loadTranslationTable{
  ["mobile__guanyinping"] = "关银屏",
  ["#mobile__guanyinping"] = "武姬",
  --["illustrator:mobile__guanyinping"] = "",

  ["~mobile__guanyinping"] = "",
}

--势陈到 田丰 黄祖 庞羲 孙韶 邢道荣 国渊 陆郁生

return extension
