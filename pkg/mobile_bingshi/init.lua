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

General:new(extension, "mobile__lougui", "wei", 3):addSkills { "guansha", "jiyul" }
Fk:loadTranslationTable{
  ["mobile__lougui"] = "娄圭",
  ["#mobile__lougui"] = "一日之寒",

  ["~mobile__lougui"] = "丞相留步，老夫告辞。",
}

General:new(extension, "m_shi__yuji", "qun", 3):addSkills { "fujiy", "daozhuan" }
Fk:loadTranslationTable{
  ["m_shi__yuji"] = "势于吉",
  ["#m_shi__yuji"] = "夙仙望道",

  ["~m_shi__yuji"] = "子为愚者，尚迷不信道，堕卑贱苦岂不哀哉？",
  ["!m_shi__yuji"] = "夫寿命，天之重宝也，所以私有德，不可伪致。",
}

General:new(extension, "mobile__yanghong", "qun", 3):addSkills { "mobile__jianji", "mobile__yuanmo" }
Fk:loadTranslationTable{
  ["mobile__yanghong"] = "杨弘",
  ["#mobile__yanghong"] = "柔迩驭远",

  ["~mobile__yanghong"] = "今日固死，死有何惧。",
}

return extension
