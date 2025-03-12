local extension = Package:new("mobile_bingshi")
extension.extensionName = "mobile"

extension:loadSkillSkelsByPath("./packages/mobile/pkg/mobile_bingshi/skills")

Fk:loadTranslationTable{
  ["mobile_bingshi"] = "手杀-兵势篇",
  ["m_shi"] = "势",
}

General:new(extension, "m_shi__taishici", "wu", 4):addSkills { "mobile__hanzhan", "zhanlie", "mobile__zhenfeng" }
Fk:loadTranslationTable{
  ["m_shi__taishici"] = "势太史慈",
  ["#m_shi__taishici"] = "志踏天阶",

  ["~m_shi__taishici"] = "身证大义，魂念江东……",
  ["!m_shi__taishici"] = "幸遇伯符，吾之壮志成矣！",
}

General:new(extension, "m_shi__dongzhao", "wei", 3):addSkills { "miaolue", "yingjia" }
Fk:loadTranslationTable{
  ["m_shi__dongzhao"] = "势董昭",
  ["#m_shi__dongzhao"] = "陈筹定势",

  --["~m_shi__dongzhao"] = "",
}

return extension
