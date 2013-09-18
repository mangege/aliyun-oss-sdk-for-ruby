# -*- encoding : utf-8 -*-
require 'aliyun/oss'
include Aliyun::OSS

#连接信息
Aliyun::OSS::Base.establish_connection!(
  :server => 'oss.aliyuncs.com', #可不填,默认为此项
  :access_key_id     => 'qhK37WBkar7QikAq', 
  :secret_access_key => 'zHGQkww2w14u27lOvht3eeqROEs5QS'
)

#bucket
Service.buckets #罗列Bucket
Bucket.list

Bucket.create('kitty') #创建Bucket
Bucket.create('kitty', access: 'public-read') #创建Bucket时指定权限,如果此Bucket,则只修改权限

kitty = Bucket.find('kitty') #查找Bucket

kitty.objects #罗列此Bucket的所有文件 TODO size
Bucket.objects('kitty')
kitty.objects(:marker => 'm', :max_keys => 2, :prefix => 'jazz') #可选的参数

obj = kitty.new_object #在此Bucket新建Object
obj.key = 'test.txt'
obj.value = 'hello world'
obj.store

kitty.find('test.txt')
kitty['test.txt'] #根据object name获取此Bucket的object
kitty.each{ |o| puts o}  #迭代此Bucket下的所有object

kitty.acl #获取权限
kitty.acl(:public_read_wirte) #修改权限 

kitty.delete #删除此bucket,不为空报错
kitty.delete_all #清空bucket

require 'open-uri'
aliyun_logo = open('http://static.aliyun.com/images/www-summerwind/logo.gif')

#object
OSSObject.store('aliyun_logo.gif', aliyun_logo, 'kitty') #上传新文件
OSSObject.store('aliyun_logo.gif', aliyun_logo, 'kitty', content_type: 'application/octet-stream') #手动指定Content-Type

OSSObject.exists?('aliyun_logo.gif', 'kitty') #判断文件是否存在
logo = OSSObject.find('aliyun_logo.gif', 'kitty') #查找文件,不下载文件内容
logo.value #下载文件
OSSObject.value('aliyun_logo.gif', 'kitty') #直接下载文件

open('song.mp3', 'w') do |file| #边下载边保存
  OSSObject.stream('song.mp3', 'jukebox') do |chunk|
    file.write chunk
  end
end

logo.about #获取文件信息,content-type,content-length等
logo.metadata #获取用户自定义metadata
logo.metadata[:v] = 1 #设置自定义metadata
logo.store
OSSObject.store('aliyun_logo.gif', aliyun_logo, 'kitty', 'x-oss-meta-v2' => 2) #上传文件时就设置metadata

OSSObject.copy('aliyun_logo.gif', 'logo.gif', 'kitty') #复制文件
OSSObject.rename('logo.gif', 'aliyun.gif', 'kitty') #重命名文件, 支持实例方法 logo.rename('aliyun.gif')
OSSObject.delete('aliyun.gif', 'kitty') #删除文件

logo.url #url签名
logo.url(:authenticated => false) #不包含签名信息 http://oss.aliyuncs.com/kitty/aliyun_logo.gif"
OSSObject.url_for('aliyun_logo.gif', 'kitty', :expires_in => 30) #30秒过期

#设置默认的bucket
class JukeBoxSong < Aliyun::OSS::OSSObject
  set_current_bucket_to 'jukebox'
end
other_song = 'baby-please-come-home.mp3'
JukeBoxSong.store(other_song, open(other_song))
