Sys.setenv(HADOOP_CONF="/data/hadoop/etc/hadoop")
Sys.setenv(YARN_CONF="/data/hadoop/etc/hadoop")
Sys.setenv(SPARK_HOME="/data/hadoop/spark/")
Sys.setenv(JAVA_HOME="/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.99-2.6.5.0.el7_2.x86_64/")

.libPaths(c(file.path(Sys.getenv("SPARK_HOME"), "R/lib"), .libPaths()))
library(SparkR)
library(magrittr)
library(tm)

## Starting

sc = sparkR.init("local[4]")
sqlContext = sparkRSQL.init(sc)

#getjson file
j = read.json(sqlContext, "hdfs://localhost:8020/data/reddit/large.json")

words=select(j, j$body, j$created_utc)
word_res = mutate(words, created = from_unixtime(words$created_utc)) %>%
  mutate(., day=date_format(.$created, "D")) 


stop=c(stopwords(kind = "en"), "" )
stop =c(stop, gsub("'", '', stop))


valentine= select(filter(word_res, word_res$day == 45), word_res$body)
valentine1 = mutate(valentine, clean = regexp_replace(valentine$body, "[0-9,\\-\\[\\]\"'`.?()’—!⌈_+^#@$%*;:/|\\<>&\n]","") %>% lower())
valentine1 = selectExpr(valentine1, "split(clean,' ') AS words")
valentine2 = select(valentine1, explode(valentine1$words))
valentine2$col = trim(valentine2$col)
valentine3 = group_by(valentine2, "col") %>% count()
res_val = arrange(valentine3, desc(valentine3$count))%>% head(n=150)
res_val=res_val[!(res_val$col %in% stop),]


day1= select(filter(word_res, word_res$day == 24), word_res$body)
day1 = mutate(day1, clean = regexp_replace(day1$body, "[0-9,\\-\\[\\]\"'`.?()’—!⌈_+^#@$%*;:/|\\<>&\n]","") %>% lower())
day1 = selectExpr(day1, "split(clean,' ') AS words")
day1 = select(day1, explode(day1$words))
day1$col = trim(day1$col)
day1 = group_by(day1, "col") %>% count()
res_val1 = arrange(day1, desc(day1$count))%>% head(n=150)
res_val1=res_val1[!(res_val1$col %in% stop),]

day2= select(filter(word_res, word_res$day == 57), word_res$body)
day2 = mutate(day2, clean = regexp_replace(day2$body, "[0-9,\\-\\[\\]\"'`.?()’—!⌈_+^#@$%*;:/|\\<>&\n]","") %>% lower())
day2 = selectExpr(day2, "split(clean,' ') AS words")
day2 = select(day2, explode(day2$words))
day2$col = trim(day2$col)
day2 = group_by(day2, "col") %>% count()
res_val2 = arrange(day2, desc(day2$count))%>% head(n=150)
res_val2=res_val2[!(res_val2$col %in% stop),]
#getjson file

#feb 3, feb26
save(res_val,res_val1,res_val2, file="task3.Rdata")

res = select(j, j$subreddit, j$created_utc) 
res_t = mutate(res, created = from_unixtime(res$created_utc)) %>%
  mutate(., month=month(.$created), wday=date_format(.$created,"E"), rounded=round(.$created_utc/3600)*3600, 
         hour=date_format(.$created, "H")) 
res1 = group_by(res_t, res_t$month, res_t$subreddit) %>% count()

res2=group_by(res_t, res_t$wday, res_t$hour)%>% count()
res_mon=collect(filter(res2, res2$wday=="Mon"))
res_tue=collect(filter(res2, res2$wday=="Tue"))
res_wed=collect(filter(res2, res2$wday=="Wed"))
res_thu=collect(filter(res2, res2$wday=="Thu"))
res_fri=collect(filter(res2, res2$wday=="Fri"))
res_sat=collect(filter(res2, res2$wday=="Sat"))
res_sun=collect(filter(res2, res2$wday=="Sun"))



res2agg=group_by(res_t, res_t$rounded)%>% count()
res2agg=collect(res2agg)



save(res_mon,res_tue,res_wed,res_thu, res_fri, res_sat, res_sun,res2agg, file="task2.Rdata")
plot(res_mon$count, x=res_mon$hour, main="monday posts", xlab="hours", col="blue")
plot(res_tue$count, x=res_tue$hour, main="tuesday posts", xlab="hours", col="red")
plot(res_wed$count, x=res_wed$hour, main="wednesday posts", xlab="hours", col="brown")
plot(res_thu$count, x=res_thu$hour, main="thursday posts", xlab="hours", col="cyan")
plot(res_fri$count, x=res_fri$hour, main="friday posts", xlab="hours", col="green")
plot(res_sat$count, x=res_sat$hour, main="saturday posts", xlab="hours", col="magenta")
plot(res_sun$count, x=res_sun$hour, main="sunday posts", xlab="hours", col="black")
plot(res2agg$count, x=as.POSIXct(res2agg$rounded, origin="1970-01-01"), main="aggregate posts", xlab="hours over three months", col="black")

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







#####TASK 3




#STOPPING

sparkR.stop() # Stop sparkR

#task 1 answer
#load("~/Team7_hw6/task1.Rdata")

