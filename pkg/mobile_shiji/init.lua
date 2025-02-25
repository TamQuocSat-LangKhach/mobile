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
General:new(extension, "mobile__xinpi", "wei", 3):addSkills { "mobile__yinju", "mobile__chijie" }
Fk:loadTranslationTable{
  ["mobile__xinpi"] = "辛毗",
  ["#mobile__xinpi"] = "一节肃六军",
  ["illustrator:mobile__xinpi"] = "鬼画府",

  ["~mobile__xinpi"] = "生而立于朝堂，亡而留名青史，我，已无憾矣。",
}

local zhouchu = General:new(extension, "mobile__zhouchu", "wu", 4)
zhouchu:addSkills { "xianghai", "chuhai" }
zhouchu:addRelatedSkill("zhangming")
Fk:loadTranslationTable{
  ["mobile__zhouchu"] = "周处",
  ["#mobile__zhouchu"] = "英情天逸",
  ["illustrator:mobile__zhouchu"] = "枭瞳",

  ["~mobile__zhouchu"] = "改励自砥，誓除三害……",
}

General:new(extension, "mobile__wujing", "wu", 4):addSkills { "heji", "liubing" }
Fk:loadTranslationTable{
  ["mobile__wujing"] = "吴景",
  ["#mobile__wujing"] = "助吴征战",
  ["cv:mobile__wujing"] = "虞晓旭",

  ["~mobile__wujing"] = "贼寇未除，奈何吾身先丧……",
}

General:new(extension, "wangfuzhaolei", "shu", 4):addSkills { "xunyi" }
Fk:loadTranslationTable{
  ["wangfuzhaolei"] = "王甫赵累",
  ["#wangfuzhaolei"] = "忱忠不移",
  ["illustrator:wangfuzhaolei"] = "游漫美绘",

  ["~wangfuzhaolei"] = "誓死……追随将军左右……",
}

local yanghu = General:new(extension, "mobile__yanghu", "qun", 3)
yanghu.subkingdom = "jin"
yanghu:addSkills { "mobile__mingfa", "rongbei" }
Fk:loadTranslationTable{
  ["mobile__yanghu"] = "羊祜",
  ["#mobile__yanghu"] = "鹤德璋声",
  ["illustrator:mobile__yanghu"] = "白",

  ["~mobile__yanghu"] = "此生所憾，唯未克东吴也……",
}

General:new(extension, "nos__mifuren", "shu", 3, 3, General.Female):addSkills { "nos__cunsi", "nos__guixiu" }
Fk:loadTranslationTable{
  ["nos__mifuren"] = "糜夫人",
  ["#nos__mifuren"] = "乱世沉香",
  ["illustrator:nos__mifuren"] = "M云涯",

  ["~nos__mifuren"] = "子龙将军，请保重……",
}

local mifuren = General:new(extension, "mobile__mifuren", "shu", 3, 3, General.Female)
mifuren:addSkills { "mobile__guixiu", "qingyu" }
mifuren:addRelatedSkill("xuancun")
Fk:loadTranslationTable{
  ["mobile__mifuren"] = "糜夫人",
  ["#mobile__mifuren"] = "乱世沉香",
  ["illustrator:mobile__mifuren"] = "zoo",

  ["~mobile__mifuren"] = "妾命数已至，唯愿阿斗顺利归蜀……",
}

local wangling = General:new(extension, "mobile__wangling", "wei", 4)
wangling:addSkills { "xingqi", "zifu", "mibei" }
wangling:addRelatedSkill("mouli")
Fk:loadTranslationTable{
  ["mobile__wangling"] = "王凌",
  ["#mobile__wangling"] = "风节格尚",
  ["cv:mobile__wangling"] = "宋国庆",
  ["illustrator:mobile__wangling"] = "西国红云",

  ["~mobile__wangling"] = "一生尽忠事魏，不料今日晚节尽毁啊！",
}

General:new(extension, "mobile__kongrong", "qun", 3):addSkills { "mobile__mingshi", "mobile__lirang" }
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

--许靖暂无

General:new(extension, "xiangchong", "shu", 4):addSkills { "guying", "muzhen" }
Fk:loadTranslationTable{
  ["xiangchong"] = "向宠",
  ["#xiangchong"] = "镇军之岳",
  ["cv:xiangchong"] = "虞晓旭",
  ["illustrator:xiangchong"] = "凝聚永恒",

  ["~xiangchong"] = "蛮夷怀异，战乱难平……",
}

General:new(extension, "liuzhang", "qun", 3):addSkills { "jutu", "yaohu", "huaibi" }
Fk:loadTranslationTable{
  ["liuzhang"] = "刘璋",
  ["#liuzhang"] = "半圭黯暗",
  ["illustrator:liuzhang"] = "鬼画府",

  ["~liuzhang"] = "引狼入室，噬脐莫及啊！",
}

General:new(extension, "nos__huaxin", "wei", 3):addSkills { "renshih", "debao", "buqi" }
Fk:loadTranslationTable{
  ["nos__huaxin"] = "华歆",
  ["#nos__huaxin"] = "清素拂浊",
  ["illustrator:nos__huaxin"] = "凡果",

  ["~nos__huaxin"] = "年老多病，上疏乞身……",
}

General:new(extension, "mobile__huaxin", "wei", 3):addSkills { "yuanqing", "shuchen" }
Fk:loadTranslationTable{
  ["mobile__huaxin"] = "华歆",
  ["#mobile__huaxin"] = "清素拂浊",
  ["illustrator:mobile__huaxin"] = "游漫美绘",

  ["~mobile__huaxin"] = "为虑国计，身损可矣……",
}

General:new(extension, "zhangzhongjing", "qun", 3):addSkills { "jishi", "liaoyi", "binglun" }
Fk:loadTranslationTable{
  ["zhangzhongjing"] = "张仲景",
  ["#zhangzhongjing"] = "医理圣哲",
  ["illustrator:zhangzhongjing"] = "鬼画府",

  ["~zhangzhongjing"] = "得人不传，恐成坠绪……",
}

General:new(extension, "mobile__zhangwen", "wu", 3):addSkills { "gebo", "mobile__songshu" }
Fk:loadTranslationTable{
  ["mobile__zhangwen"] = "张温",
  ["#mobile__zhangwen"] = "抱德炀和",
  ["illustrator:mobile__zhangwen"] = "凝聚永恒",

  ["~mobile__zhangwen"] = "自招罪谴，诚可悲疚……",
}

General:new(extension, "caizhenji", "wei", 3, 3, General.Female):addSkills { "sheyi", "tianyin" }
Fk:loadTranslationTable{
  ["caizhenji"] = "蔡贞姬",
  ["#caizhenji"] = "舍心顾复",
  ["illustrator:caizhenji"] = "M云涯",

  ["~caizhenji"] = "世誉吾为贤妻，吾愧终不为良母……",
}

local qiaogong = General:new(extension, "qiaogong", "wu", 3)
qiaogong:addSkills { "yizhu", "luanchou" }
qiaogong:addRelatedSkill("gonghuan")
Fk:loadTranslationTable{
  ["qiaogong"] = "桥公",
  ["#qiaogong"] = "高风硕望",
  ["illustrator:qiaogong"] = "凝聚永恒",

  ["~qiaogong"] = "为父所念，为汝二人啊……",
}

General:new(extension, "godhuatuo", "god", 3):addSkills { "wuling", "youyi" }
Fk:loadTranslationTable{
  ["godhuatuo"] = "神华佗",
  ["#godhuatuo"] = "悬壶济世",
  ["illustrator:godhuatuo"] = "吴涛",

  ["~godhuatuo"] = "人间诸疾未解，老夫怎入轮回……",
  ["$godhuatuo_win_audio"] = "但愿世间人无病，何惜架上药生尘。",
}
for _, name in ipairs({"wulingHu", "wulingLu", "wulingXiong", "wulingYuan", "wulingHe"}) do
  local card = fk.CreateCard{
    name = name,
    type = Card.TypeTrick,
  }
  extension:loadCardSkels{card}
  extension:addCardSpec(name)
end

General:new(extension, "godlusu", "god", 3):addSkills { "tamo", "dingzhou", "zhimeng" }
Fk:loadTranslationTable{
  ["godlusu"] = "神鲁肃",
  ["#godlusu"] = "兴吴之邓禹",
  ["illustrator:godlusu"] = "漫想族",

  ["~godlusu"] = "常计小利，何成大局……",
  ["$godlusu_win_audio"] = "至尊高坐天中，四海皆在目下！",
}

--勇：孙翊 高览 宗预 花鬘 陈武董袭 文鸯 袁涣 王双
General:new(extension, "sunyi", "wu", 4):addSkills { "zaoli" }
Fk:loadTranslationTable{
  ["sunyi"] = "孙翊",
  ["#sunyi"] = "骁悍激躁",
  ["illustrator:sunyi"] = "鬼画府",

  ["~sunyi"] = "尔等……为何如此……",
}

General:new(extension, "mobile__gaolan", "qun", 4):addSkills { "jungong", "dengli" }
Fk:loadTranslationTable{
  ["mobile__gaolan"] = "高览",
  ["#mobile__gaolan"] = "绝击坚营",
  ["cv:mobile__gaolan"] = "曹真",
  ["illustrator:mobile__gaolan"] = "兴游",

  ["~mobile__gaolan"] = "满腹忠肝，难抵一句谮言……唉！",
}

--宗预暂无

General:new(extension, "mobile__huaman", "shu", 4, 4, General.Female):addSkills { "xiangzhen", "fangzong", "xizhan" }
Fk:loadTranslationTable{
  ["mobile__huaman"] = "花鬘",
  ["#mobile__huaman"] = "薮泽清影",
  ["illustrator:mobile__huaman"] = "alien",

  ["~mobile__huaman"] = "战事已定，吾愿终亦得偿……",
}

--陈武董袭暂无

local wenyang = General:new(extension, "mobile__wenyang", "wei", 4)
wenyang.subkingdom = "wu"
wenyang:addSkills { "quedi", "chuifeng", "chongjian", "mobile__choujue" }
Fk:loadTranslationTable{
  ["mobile__wenyang"] = "文鸯",
  ["#mobile__wenyang"] = "独骑破军",
  ["illustrator:mobile__wenyang"] = "鬼画府",

  ["~mobile__wenyang"] = "半生功业，而见疑于一家之言，岂能无怨！",
}

General:new(extension, "yuanhuan", "wei", 3):addSkills { "qingjue", "fengjie" }
Fk:loadTranslationTable{
  ["yuanhuan"] = "袁涣",
  ["#yuanhuan"] = "随车致雨",
  ["illustrator:yuanhuan"] = "凝聚永恒",

  ["~yuanhuan"] = "乱世之中，有礼无用啊……",
}

General:new(extension, "mobile__wangshuang", "wei", 4):addSkills { "yiyongw", "shanxie" }
Fk:loadTranslationTable{
  ["mobile__wangshuang"] = "王双",
  ["#mobile__wangshuang"] = "边城猛兵",
  ["illustrator:mobile__wangshuang"] = "铁杵文化",

  ["~mobile__wangshuang"] = "啊？速回主营！啊！",
}

--严：蒋琬 蒋钦 崔琰 张昌蒲 吕范 皇甫嵩 朱儁 刘巴
General:new(extension, "jiangwan", "shu", 3):addSkills { "zhenting", "mobile__jincui" }
Fk:loadTranslationTable{
  ["jiangwan"] = "蒋琬",
  ["#jiangwan"] = "方整威重",
  ["illustrator:jiangwan"] = "凡果",

  ["~jiangwan"] = "臣即将一死，辅国之事文伟可继……",
}



return extension
