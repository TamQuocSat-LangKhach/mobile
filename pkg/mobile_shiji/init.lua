local extension = Package:new("mobile_shiji")
extension.extensionName = "mobile"

extension:loadSkillSkels(require("packages.mobile.pkg.mobile_shiji.skills"))

Fk:loadTranslationTable{
  ["mobile_shiji"] = "手杀-始计篇",
}

--智：王粲 陈震 荀谌 费祎 骆统 杜预 孙邵 卞夫人 神郭嘉 神荀彧
General:new(extension, "mobile__wangcan", "wei", 3):addSkills { "wisdom__qiai", "wisdom__shanxi" }
Fk:loadTranslationTable{
  ["mobile__wangcan"] = "王粲",
  ["#mobile__wangcan"] = "词章纵横",
  ["illustrator:mobile__wangcan"] = "鬼画府",

  ["~mobile__wangcan"] = "悟彼下泉人，喟然伤心肝……",
}

General:new(extension, "chenzhen", "shu", 3):addSkills { "shameng" }
Fk:loadTranslationTable{
  ["chenzhen"] = "陈震",
  ["#chenzhen"] = "歃盟使节",
  ["illustrator:chenzhen"] = "成都劲心",

  ["~chenzhen"] = "若毁盟约，则两败俱伤！",
}

General:new(extension, "nos__xunchen", "qun", 3):addSkills { "jianzhan", "duoji" }
Fk:loadTranslationTable{
  ["nos__xunchen"] = "荀谌",
  ["#nos__xunchen"] = "谋刃略锋",
  ["illustrator:nos__xunchen"] = "鬼画府",

  ["~nos__xunchen"] = "惟愿不堕颍川荀氏之名……",
}

General:new(extension, "mobile__feiyi", "shu", 3):addSkills { "jianyu", "os__shengxi" }
Fk:loadTranslationTable{
  ["mobile__feiyi"] = "费祎",
  ["#mobile__feiyi"] = "蜀汉名相",
  ["illustrator:mobile__feiyi"] = "游漫美绘",

  ["$os__shengxi_mobile__feiyi1"] = "承葛公遗托，富国安民。",
  ["$os__shengxi_mobile__feiyi2"] = "保国治民，敬守社稷。",
  ["~mobile__feiyi"] = "吾何惜一死，惜不见大汉中兴矣。",
}

General:new(extension, "luotong", "wu", 4):addSkills { "qinzheng" }
Fk:loadTranslationTable{
  ["luotong"] = "骆统",
  ["#luotong"] = "力政人臣",
  ["illustrator:luotong"] = "鬼画府",

  ["~luotong"] = "臣统之大愿，足以死而不朽矣。",
}

local duyu = General:new(extension, "mobile__duyu", "qun", 4)
duyu.subkingdom = "jin"
duyu:addSkills { "wuku", "mobile__sanchen" }
duyu:addRelatedSkill("miewu")
Fk:loadTranslationTable{
  ["mobile__duyu"] = "杜预",
  ["#mobile__duyu"] = "文成武德",
  ["illustrator:mobile__duyu"] = "鬼画府",

  ["~mobile__duyu"] = "洛水圆石，遂道向南，吾将以俭自完耳……",
}

General:new(extension, "mobile__sunshao", "wu", 3):addSkills { "dingyi", "zuici", "fubi" }
Fk:loadTranslationTable{
  ["mobile__sunshao"] = "孙邵",
  ["#mobile__sunshao"] = "创基抉政",
  ["designer:mobile__sunshao"] = "Loun老萌",
  ["illustrator:mobile__sunshao"] = "君桓文化",

  ["~mobile__sunshao"] = "江东将相各有所能，奈何心向不一……",
}

General:new(extension, "mobile__bianfuren", "wei", 3, 3, General.Female):addSkills { "mobile__wanwei", "mobile__yuejian" }
Fk:loadTranslationTable{
  ["mobile__bianfuren"] = "卞夫人",
  ["#mobile__bianfuren"] = "内助贤后",
  ["illustrator:mobile__bianfuren"] = "芝芝不加糖",

  ["~mobile__bianfuren"] = "孟德大人，妾身可以再伴你身边了……",
}

local godguojia = General:new(extension, "godguojia", "god", 3)
godguojia:addSkills { "mobile__huishi", "mobile__tianyi", "huishig" }
godguojia:addRelatedSkill("zuoxing")
Fk:loadTranslationTable{
  ["godguojia"] = "神郭嘉",
  ["#godguojia"] = "星月奇佐",
  ["illustrator:godguojia"] = "木美人",

  ["~godguojia"] = "可叹桢干命也迂……",
  ["$godguojia_win_audio"] = "既为奇佐，怎可徒有虚名？",
}

General:new(extension, "godxunyu", "god", 3):addSkills { "tianzuo", "lingce", "dinghan" }
Fk:loadTranslationTable{
  ["godxunyu"] = "神荀彧",
  ["#godxunyu"] = "洞心先识",
  ["illustrator:godxunyu"] = "枭瞳",

  ["~godxunyu"] = "宁鸣而死，不默而生……",
  ["$godxunyu_win_audio"] = "汉室复兴，指日可待！",
}

--信：辛毗 周处 吴景 王甫赵累 羊祜 糜夫人 王凌 孔融 神太史慈 神孙策
--General:new(extension, "mobile__xinpi", "wei", 3):addSkills { "mobile__yinju", "mobile__chijie" }
Fk:loadTranslationTable{
  ["mobile__xinpi"] = "辛毗",
  ["#mobile__xinpi"] = "一节肃六军",
  ["illustrator:mobile__xinpi"] = "鬼画府",

  ["~mobile__xinpi"] = "生而立于朝堂，亡而留名青史，我，已无憾矣。",
}

--local zhouchu = General:new(extension, "mobile__zhouchu", "wu", 4)
--zhouchu:addSkills { "xianghai", "chuhai" }
--zhouchu:addRelatedSkill("zhangming")
Fk:loadTranslationTable{
  ["mobile__zhouchu"] = "周处",
  ["#mobile__zhouchu"] = "英情天逸",
  ["illustrator:mobile__zhouchu"] = "枭瞳",

  ["~mobile__zhouchu"] = "改励自砥，誓除三害……",
}

--General:new(extension, "mobile__wujing", "wu", 4):addSkills { "heji", "liubing" }
Fk:loadTranslationTable{
  ["mobile__wujing"] = "吴景",
  ["#mobile__wujing"] = "助吴征战",
  ["cv:mobile__wujing"] = "虞晓旭",

  ["~mobile__wujing"] = "贼寇未除，奈何吾身先丧……",
}

--General:new(extension, "wangfuzhaolei", "shu", 4):addSkills { "xunyi" }
Fk:loadTranslationTable{
  ["wangfuzhaolei"] = "王甫赵累",
  ["#wangfuzhaolei"] = "忱忠不移",
  ["illustrator:wangfuzhaolei"] = "游漫美绘",

  ["~wangfuzhaolei"] = "誓死……追随将军左右……",
}

--local yanghu = General:new(extension, "mobile__yanghu", "qun", 3)
--yanghu.subkingdom = "jin"
--yanghu:addSkills { "mobile__mingfa", "rongbei" }
Fk:loadTranslationTable{
  ["mobile__yanghu"] = "羊祜",
  ["#mobile__yanghu"] = "鹤德璋声",
  ["illustrator:mobile__yanghu"] = "白",

  ["~mobile__yanghu"] = "此生所憾，唯未克东吴也……",
}

--General:new(extension, "nos__mifuren", "shu", 3, 3, General.Female):addSkills { "nos__cunsi", "nos__guixiu" }
Fk:loadTranslationTable{
  ["nos__mifuren"] = "糜夫人",
  ["#nos__mifuren"] = "乱世沉香",
  ["illustrator:nos__mifuren"] = "M云涯",

  ["~nos__mifuren"] = "子龙将军，请保重……",
}

--local mifuren = General:new(extension, "mobile__mifuren", "shu", 3, 3, General.Female)
--mifuren:addSkills { "mobile__guixiu", "qingyu" }
--mifuren:addRelatedSkill("xuancun")
Fk:loadTranslationTable{
  ["mobile__mifuren"] = "糜夫人",
  ["#mobile__mifuren"] = "乱世沉香",
  ["illustrator:mobile__mifuren"] = "zoo",

  ["~mobile__mifuren"] = "妾命数已至，唯愿阿斗顺利归蜀……",
}

--local wangling = General:new(extension, "mobile__wangling", "wei", 4)
--wangling:addSkills { "xingqi", "zifu", "mibei" }
--wangling:addRelatedSkill("mouli")
Fk:loadTranslationTable{
  ["mobile__wangling"] = "王凌",
  ["#mobile__wangling"] = "风节格尚",
  ["cv:mobile__wangling"] = "宋国庆",
  ["illustrator:mobile__wangling"] = "西国红云",

  ["~mobile__wangling"] = "一生尽忠事魏，不料今日晚节尽毁啊！",
}

--General:new(extension, "mobile__kongrong", "qun", 3):addSkills { "mobile__mingshi", "mobile__lirang" }
Fk:loadTranslationTable{
  ["mobile__kongrong"] = "孔融",
  ["#mobile__kongrong"] = "凛然重义",
  ["illustrator:mobile__kongrong"] = "JanusLausDeo",

  ["~mobile__kongrong"] = "不遵朝仪？诬害之词也！",
}

General:new(extension, "godsunce", "god", 1, 6):addSkills { "yingba", "fuhai", "pinghe" }
Fk:loadTranslationTable{
  ["godsunce"] = "神孙策",
  ["#godsunce"] = "踞江鬼雄",
  ["illustrator:godsunce"] = "枭瞳",

  ["~godsunce"] = "无耻小人！竟敢暗算于我……",
  ["$godsunce_win_audio"] = "平定三郡，稳据江东！",
}

local godtaishici =  General:new(extension, "godtaishici", "god", 4)
godtaishici:addSkills { "dulie", "powei" }
godtaishici:addRelatedSkill("shenzhuo")
Fk:loadTranslationTable{
  ["godtaishici"] = "神太史慈",
  ["#godtaishici"] = "义信天武",
  ["illustrator:godtaishici"] = "枭瞳",

  ["~godtaishici"] = "魂归……天地……",
  ["$godtaishici_win_audio"] = "执此神弓，恭行天罚！",
}

--仁：许靖 向宠 刘璋 华歆 张仲景 张温 蔡贞姬 桥公 神华佗 神鲁肃

--勇：孙翊 高览 宗预 花鬘 陈武董袭 文鸯 袁涣 王双

--严：蒋琬 蒋钦 崔琰 张昌蒲 吕范 皇甫嵩 朱儁 刘巴

return extension
