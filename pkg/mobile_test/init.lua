local extension = Package:new("mobile_test")
extension.extensionName = "mobile"

extension:loadSkillSkels(require("packages.mobile.pkg.mobile_test.skills"))

Fk:loadTranslationTable{
  ["mobile_test"] = "手杀-测试服",
  ["m_friend"] = "友",
}

General:new(extension, "zhangbu", "wu", 4):addSkills { "chengxiong", "wangzhuan" }
Fk:loadTranslationTable{
  ["zhangbu"] = "张布",
  ["#zhangbu"] = "主胜辅义",
  --["illustrator:zhangbu"] = "",

  --["~zhangbu"] = "",
}

General:new(extension, "m_friend__zhugeliang", "qun", 3):addSkills { "yance", "fangqiu", "zhugeliang__gongli" }
Fk:loadTranslationTable{
  ["m_friend__zhugeliang"] = "友诸葛亮",
  ["#m_friend__zhugeliang"] = "龙骧九天",
  --["illustrator:m_friend__zhugeliang"] = "",

  ["~m_friend__zhugeliang"] = "吾既得明主，纵不得良时，亦当全力一试……",
  ["$m_friend__zhugeliang_win_audio"] = "鼎足之势若成，则将军中原可图也。",
}

General:new(extension, "m_friend__pangtong", "qun", 3):addSkills { "friend__manjuan", "friend__yangming", "pangtong__gongli" }
Fk:loadTranslationTable{
  ["m_friend__pangtong"] = "友庞统",
  ["#m_friend__pangtong"] = "凤翥南地",
  --["illustrator:m_friend__pangtong"] = "",

  ["~m_friend__pangtong"] = "大事未竟，惜哉，惜哉……",
}

General:new(extension, "m_friend__xushu", "qun", 3):addSkills { "xiaxing", "qihui", "xushu__gongli" }
Fk:loadTranslationTable{
  ["m_friend__xushu"] = "友徐庶",
  ["#m_friend__xushu"] = "潜悟诲人",
  --["illustrator:m_friend__xushu"] = "",

  ["~m_friend__xushu"] = "百姓陷于苦海，而吾却难以济之……",
}

General:new(extension, "m_friend__shitao", "qun", 3):addSkills { "qinying", "lunxiong", "shitao__gongli" }
Fk:loadTranslationTable{
  ["m_friend__shitao"] = "友石韬",
  ["#m_friend__shitao"] = "月堕窠臼",
  --["illustrator:m_friend__shitao"] = "",

  ["~m_friend__shitao"] = "空有一腔热血，却是报国无门……",
}

General:new(extension, "m_friend__cuijun", "qun", 3):addSkills { "shunyi", "biwei", "cuijun__gongli" }
Fk:loadTranslationTable{
  ["m_friend__cuijun"] = "友崔钧",
  ["#m_friend__cuijun"] = "日奋金丝",
  --["illustrator:m_friend__cuijun"] = "",

  ["~m_friend__cuijun"] = "与君等交何其之快，只惜无再聚之日矣……",
}

return extension
