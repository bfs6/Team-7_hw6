Sys.setenv(HADOOP_CONF="/data/hadoop/etc/hadoop")
Sys.setenv(YARN_CONF="/data/hadoop/etc/hadoop")
Sys.setenv(SPARK_HOME="/data/hadoop/spark/")
Sys.setenv(JAVA_HOME="/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.99-2.6.5.0.el7_2.x86_64/")

.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R/lib"), .libPaths()))
library(SparkR)
library(magrittr)


## Starting

sc = sparkR.init("local[4]")
sqlContext = sparkRSQL.init(sc)

#getjson file
j = read.json(sqlContext, "hdfs://localhost:8020/data/reddit/large.json")

res = select(j, j$subreddit, j$created_utc) 
res_t = mutate(res, created = from_unixtime(res$created_utc)) %>%
  mutate(., month=month(.$created), wday=date_format(.$created,"E"), rounded=round(.$created_utc/3600)*3600, hour=date_format(.$created, "H")) 
res1 = group_by(res_t, res_t$month, res_t$subreddit) %>% count()

res2=group_by(res_t, res_t$wday, res_t$hour)%>% count()
res_mon=filter(res2, res2$wday=="Mon")%>%head(n=24)
res_tue=filter(res2, res2$wday=="Tue")%>%head(n=24)
res_wed=filter(res2, res2$wday=="Wed")%>%head(n=24)
res_thu=filter(res2, res2$wday=="Thu")%>%head(n=24)
res_fri=filter(res2, res2$wday=="Fri")%>%head(n=24)
res_sat=filter(res2, res2$wday=="Sat")%>%head(n=24)
res_sun=filter(res2, res2$wday=="Sun")%>%head(n=24)
save(res_mon,res_tue,res_wed,res_thu, res_fri, res_sat, res_sun, file="task2.Rdata")
plot(res_mon$count, x=res_mon$hour, main="monday posts", xlab="hours", type='l', col="blue")
plot(res_tue$count, x=res_tue$hour, main="tuesday posts", xlab="hours", type='l', col="red")
plot(res_wed$count, x=res_wed$hour, main="wednesday posts", xlab="hours", type='l', col="brown")
plot(res_thu$count, x=res_thu$hour, main="thursday posts", xlab="hours", type='l', col="cyan")
plot(res_fri$count, x=res_fri$hour, main="friday posts", xlab="hours", type='l', col="green")
plot(res_sat$count, x=res_sat$hour, main="saturday posts", xlab="hours", type='l', col="magenta")
plot(res_sun$count, x=res_sun$hour, main="sunday posts", xlab="hours", type='l', col="black")




j_rank=rep(0, 150)
f_rank=rep(NA,150)
m_rank=rep(NA, 150)
res_jan = filter(res1, res1$month == 1) %>% arrange(., desc(.$count)) %>% head(n=150)

res_feb = filter(res1, res1$month == 2) %>% arrange(., desc(.$count)) %>% head(n=150)
res_mar = filter(res1, res1$month == 3) %>% arrange(., desc(.$count)) %>% head(n=150)





for(i in 1:150){
  if(res_feb$subreddit[i] %in%res_jan$subreddit ){
    f_rank[i]=which(res_jan$subreddit ==res_feb$subreddit[i])-i
  }
  if(res_mar$subreddit[i] %in% res_feb$subreddit){
    m_rank[i]=which(res_feb$subreddit==res_mar$subreddit[i])-i
  }

}
res_jan25=cbind(res_jan, j_rank)%>% head(n=25)
res_feb25=cbind(res_feb, f_rank)%>% head(n=25)
res_mar25=cbind(res_mar, m_rank)%>% head(n=25)
save(res_jan25,res_feb25,res_mar25, file="task1.Rdata")





#graph for all days from jan to march by hours

#graph 7 graphs of each day


## Stopping

sparkR.stop() # Stop sparkR

#task 1 answer
#load("~/Team7_hw6/task1.Rdata")

