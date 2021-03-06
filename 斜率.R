load('c:/data/station1050/loadings.RData')
library('dtwclust')
a=list.files('c:/data/station1050/day/tar/')
dir=paste('c:/data/station1050/day/tar/',a,sep="")
all_s_data<-NULL
all_data<-NULL
for(i in 1:length(dir)){
  load(dir[i])
  #scale:
  all_s_data<-rbind(all_s_data,data.frame(flow=day_data$volume-fm20,speed=day_data$speed-sm20,occ=day_data$occ-om20))
}
for(i in 1:length(dir)){
  load(dir[i])
  #no scale for plot:
  all_data<-rbind(all_data,day_data)
}

  #series preparation:
multi_series<-list()
for (i in 1:(288*length(dir))){
  multi_series[[i]]<-cbind(all_s_data[(i*15-14):(i*15),1],all_s_data[(i*15-14):(i*15),2],all_s_data[(i*15-14):(i*15),3])}
  #identification:
state<-vector()
state[1]<-which.min(proxy::dist(multi_series[1],multi_cluster@centroids,method='dtw'))
for(i in 2:length(multi_series)){
  dis<-proxy::dist(multi_series[i],multi_cluster@centroids,method='dtw')
  current_min<-min(dis)
  previous_min_dis<-dis[state[i-1]]
  if(abs(current_min-previous_min_dis)>50) (state[i]<-which.min(dis)
   ) else(state[i]<-state[i-1])
}
#20s to 5min:

s5<-vector()
f5<-vector()
o5<-vector()
for(i in 1:(length(multi_series))){
  f5[i]<-sum(all_data$volume[(i*15-14):(i*15)])*12/3
  o5[i]<-mean(all_data$occ[(i*15-14):(i*15)])
  s5[i]<-sum(all_data$speed[(i*15-14):(i*15)]*all_data$volume[(i*15-14):(i*15)])/sum(all_data$volume[(i*15-14):(i*15)])  #不要除以f[i]，单位不一！
}
all_five_data<-data.frame(f5,s5,o5,state)
#统计均值与标准差：
aggregate(all_five_data,by=list(all_five_data$state),mean)
aggregate(all_five_data,by=list(all_five_data$state),sd)

#计算斜率：
#流量-占有率：
k<-vector()
trans<-vector()
pon<-vector()
for(i in 2:nrow(all_five_data)){
  k[i-1]<-(all_five_data$f5[i]-all_five_data$f5[i-1])/(all_five_data$o5[i]-all_five_data$o5[i-1])
  trans[i-1]<-paste(as.character(all_five_data$state[i-1]),as.character(all_five_data$state[i]),sep=' to ')
}
for(i in 1:length(k)){
  if(is.na(k[i])) (pon[i]<-'NA'
  ) else(if(k[i]>0) (pon[i]<-'positive'
                     ) else(if(k[i]<0) (pon[i]<-'negative'
                                        ) else(pon[i]<-'zero')))
}
bar<-data.frame(k,trans,pon)
#二维列联表：
table1<-xtabs(~trans+pon,data=bar)
kinfo<-round(prop.table(table1,1),2)

###比例玫瑰图：
#变化为长格式：
library(reshape2)
kdata<-melt(kinfo)
# melt转化为了因子，下一步替换NA时，因子无法被新的字符型替换，因此要先转换为字符：
kdata$pon<-as.character(kdata$pon)
kdata$pon[is.na(kdata$pon)]<-'N'
# 为图例做准备：
kdata$pon<-factor(kdata$pon,levels = c('N','negative','positive','zero'),labels = c('不存在','负','正','零'))

ggplot(data=kdata,aes(x=trans,y=value))+geom_bar(stat="identity",aes(fill=factor(pon)))+
theme(panel.background = element_rect(fill='white', colour='white'),strip.background=element_rect(fill='white', colour='white'),legend.key.size = unit(1.0, "cm"),
legend.text = element_text(size=15),axis.text.x = element_text(size=15),axis.text.y = element_text(size=15),
axis.title.x = element_text(size = 15),axis.title.y = element_text(size = 15))+
coord_polar()+ylim(c(-0.4,1.1))+scale_fill_brewer(palette="Blues")

###个数玫瑰图：
#变化为长格式：
library(reshape2)
kdata<-melt(table1)
# melt转化为了因子，下一步替换NA时，因子无法被新的字符型替换，因此要先转换为字符：
kdata$pon<-as.character(kdata$pon)
kdata$pon[is.na(kdata$pon)]<-'N'
# 为图例做准备：
kdata$pon<-factor(kdata$pon,levels = c('N','negative','positive','zero'),labels = c('不存在','负','正','零'))

ggplot(data=kdata,aes(x=trans,y=value))+geom_bar(stat="identity",aes(fill=factor(pon)))+
  theme(panel.background = element_rect(fill='white', colour='white'),strip.background=element_rect(fill='white', colour='white'),legend.key.size = unit(1.0, "cm"),
        legend.text = element_text(size=15),axis.text.x = element_text(size=15),axis.text.y = element_text(size=15),
        axis.title.x = element_text(size = 15),axis.title.y = element_text(size = 15))+
  coord_polar()+ylim(c(-100,max(kdata$value)))
