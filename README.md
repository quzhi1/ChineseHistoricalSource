# ChineseHistoricalSource
This is my personal stash of Chinese Historical Source

声明：这是个个人项目，不要用于商业用途。

# 项目目的

我一直想用做一个史料查询系统，这样的话就能想用Google一样搜索不同史料了。目前在线能找到的各种史料大概只有txt和pdf版本，这两种都不是标准化数据，不能喂到索引系统里面。

史料的电子版

史料的文白对照不在本项目的范畴里。如果需要文白对照，我个人推荐一个移动应用"读典籍"：https://dudianji.com/mobile/

史料的电子化现在基本上弄得差不多了，这个项目就是想把电子史料标准化。

# 项目内容

这个小项目就是把txt版本的史料做两个操作：
1. 把不同汉字编码的史料标准化成utf8版本。
2. 把utf8版本的txt史料变成统一json格式

所以内容主要是三个：
1. 原始数据。
这个数据来源是"猪猪书网"：http://www.zzs5.com/txt/7871.html
（如有侵权请联系作者，我务必在第一时间删除）
2. 转码数据。
它是把上面的数据做成utf8格式的。
我用了一个在线工具"Subtitle Tools": https://subtitletools.com/convert-text-files-to-utf8-online
如果有史料上的不准确，我会在转码数据里改，而不会去改原始数据。
转码数据我也会做一下格式上的预处理。
3. json数据。这个数据就是可以放到索引系统里的标准化数据
4. 标准化算法。我用Ruby写一些Script，把utf8格式的txt史料parse成json。

# json格式
目前支持三个Attribute：史料、章节和原文。原文的每一句话都是一个json object。
范例：
```json
{
    "source": "史记",
    "chapter": "陈涉世家",
    "text": "陈胜者，阳城人也，字涉。"
}
```

# 工程进度
raw和utf8是纯手工操作，所以已完成。

Ruby Parsing已完成：
史记

# 工程笔记

## GCP Instance Setup

今天的云服务各种各样，但因为吸引的客户是企业而不是个人，所以没有多少是免费的。如果想免费只有两个办法，一种是短期试用。短期试用虽然自由，但难以持久。一种是长期但受限制。
限制的方法有限制容量和限制待机时间。
长期免费但受限制的服务我找到的只有两个：Heroku和Google Cloud Platform（GCP）。

Heroku目前不能做一个通用的Instance，只能做Application。我记得Heroku有一个免费的PostgreSQL，但有一个很紧的数量限制：10,000行。对于史料来说，这远远不够。
另一个原因是我本人不是很熟悉用SQL做索引系统，所以还是选择ElasticSearch。Heroku有一个ElasticSearch的Application，但不是免费的，所以只能放弃Heroku了。

GCP的选择就很多了。谷歌这个平台比较开放，support也很多。因为GCP基本就是谷歌版本的AWS，所以主打的业务就是通用的计算单元。AWS的计算单元叫EC2，谷歌叫Compute Engine。

谷歌虽然说是免费，但是把免费的方法藏得很深。稍有不慎就被谷歌收钱了。Medium有一篇文章讲了一下如何把Instance搞成免费的：https://medium.com/@hbmy289/how-to-set-up-a-free-micro-vps-on-google-cloud-platform-bddee893ac09
简单来说就是，机子的类型必须是f1-micro VPS，区域必须是us-central1 (Iowa), us-east1 (South Carolina)或者us-west1 (Oregon)。磁盘容量可以调成30G。

谷歌的ssh比AWS人性化多了，直接用浏览器当Terminal，非常爽。不像AWS，还要搞一个Private Key File

## 安装ElasticSearch
我用的操作系统是Debian，所以安装ElasticSearch需要下列Command（https://www.elastic.co/guide/en/elasticsearch/reference/current/deb.html）

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch
```

然后就是启动了。用`ps -p 1`查启动方式。我试了两次，第一次查出来是systemd，于是

```bash
sudo systemctl start elasticsearch.service # 启动
sudo systemctl stop elasticsearch.service # 关闭
sudo journalctl -f # Tail log
```

第二次竟然变了，变成init，于是

```bash
sudo update-rc.d elasticsearch defaults 95 10 # 设成自动启动
sudo -i service elasticsearch start # 启动
sudo -i service elasticsearch stop # 关闭
```

顺便说一下，我2014年也搞过一个ElasticSearch的个人项目，启动方式当年是类似`elasticsearch server start`。当时大版本号好像是3，现在都是7了。
这几年ElasticSearch变化快，用之前建议查一下变没变。

## ElasticSearch 网络设置
经过了各种找，发现ElasticSearch的Configuration在这里(https://www.elastic.co/guide/en/elasticsearch/reference/current/settings.html)
```
/etc/elasticsearch/elasticsearch.yml
```
然后要把network host改成GCP的Internal IP

## ElasticSearch内存设置
GCP的免费Tier只有0.6GB的内存（不给力啊老湿），而ElasticSearch的默认设置是1GB或者2GB，非常土豪。所以需要调一下JVM的设置。(https://www.elastic.co/guide/en/elasticsearch/reference/current/jvm-options.html)

```
/etc/elasticsearch/jvm.options
```

设置一下-Xmx和-Xms，都搞成300m，主要前面不要有空格。

## GCP的弃坑

GCP的免费版内存实在太小了，就算是把Heap Size变小，还是会让Instance直接死掉。我现在想先试试在Mac上搞一个Demo版本，以后估计真的要**众筹**买AWS、GCP、Heroku或者Bonsai了。

![crowd-funding](http://filmdope.com/wp-content/uploads/2009/11/oliver-twist01.jpg)

## Mac上安装ElasticSearch

经过GCP的折磨以后，本地Mac上安装就非常爽了：

```bash
brew install elasticsearch
brew services start elasticsearch # Background service running
elasticsearch # Test in shell
brew install kibana
brew services start kibana # Background service running
kibana # Test in shell
```

Elasticsearch默认port是9200，Kibana默认port是5601

Log和Config什么的可以在这儿找：https://www.elastic.co/guide/en/elasticsearch/reference/current/brew.html

## 史记
史记这个txt比较整齐，从第五行开始是正文（为了方便我直接把前四行手工删了），所有章节都以"●卷XXX第XXX"开始。

为了以后便于搜索，章节名称我做一下简化。忽略卷目和章节数，直接写章节名称。比如，"●卷一·五帝本纪第一"，简化为"五帝本纪"。

史记包括太史公自序一共130篇，不是很长。

需要注意的是，这个txt换行并不是一句话的终点。也就是说，虽然换行了，但这句话还没完。所以不能通过换行来做分界。
如果分段的话，我可以用中文的分段标记，也就是前面空两格。（也就是四个拉丁字母空格）

## 汉书
汉书末尾有一些关于汉书的介绍，还有目录，不应该做索引，所以删去。

汉书这个史料格式比较奇怪，它每一章是一行，然后用空格分行。

卷十一以后的章节名都是乱码，我手工给改过来了。

汉书里的表就不索引了，系文倒是可以索引，有兴趣的同学可以来这里查：https://ctext.org/han-shu/

班固把王莽放到那么靠后，估计是故意的吧。

发现“律历志第一下”里面空格乱加。我不熟悉“统母”、“五步”这类的术语，只能当做独立的一段了。

第一章这几个字“卷一上  高帝纪第一上”有一个找不到的特殊字符"﻿"，我不知道怎么把它搞掉。最简单的一个Hack就是加一个空行，然后把出来的json的第一个元素删掉。

章节还是把第XX上和第XX下合一下吧，不然可视性太差。