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
res = mutate(res, created = from_unixtime(res$created_utc)) %>%
  mutate(., month=month(.$created), wday=date_format(.$created,"E")) 
res = group_by(res, res$month, res$subreddit) %>% count()

j_rank=rep(0, 100)
f_rank=rep(NA,100)
m_rank=rep(NA, 100)
res_jan = filter(res, res$month == 1) %>% arrange(., desc(.$count)) %>% head(n=100)

res_feb = filter(res, res$month == 2) %>% arrange(., desc(.$count)) %>% head(n=100)
res_mar = filter(res, res$month == 3) %>% arrange(., desc(.$count)) %>% head(n=100)

save(res_jan,res_feb,res_mar, file="task1.Rdata")



for(i in 1:100){
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


## Stopping

sparkR.stop() # Stop sparkR



