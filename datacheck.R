library(dplyr)
setwd("C:/UW/SP23/DATA514/Project")


####################################Calendar data################################

cal1<- read.csv('Los Angelescalendar.csv')
cal2<- read.csv('Portlandcalendar.csv')
cal3<- read.csv('Salemcalendar.csv')
cal4<- read.csv('SDcalendar.csv')

colnames(cal1)
colnames(cal2)
colnames(cal3)
colnames(cal4)

#Check NAs, if present remove
colMeans(is.na(cal1)) * 100
cal1 <- na.omit(cal1)
cal1$city <- 'LA'

colMeans(is.na(cal2)) * 100
cal2$city <- 'Portland'

colMeans(is.na(cal3)) * 100
cal3 <- na.omit(cal3)
cal3$city <- 'Salem'

colMeans(is.na(cal4)) * 100
cal4$city <- 'SD'

#Combine all data
cal <- rbind(cal1,cal2,cal3,cal4)
colMeans(is.na(cal)) * 100
write.csv(cal,'Calendar.csv',row.names = FALSE)

##################################Review data###################################

rev1<- read.csv('Los Angelesreviews.csv')
rev2<- read.csv('Portlandreviews.csv')
rev3<- read.csv('Salemreviews.csv')
rev4<- read.csv('SDreviews.csv')

colnames(rev1)
colnames(rev2)
colnames(rev3)
colnames(rev4)

#Check NAs, if present remove
colMeans(is.na(rev1)) * 100
rev1 <- na.omit(rev1)
rev1$city<-'LA'

colMeans(is.na(rev2)) * 100
rev2 <- na.omit(rev2)
rev2$city<-'Portland'

colMeans(is.na(rev3)) * 100
rev3$city<-'Salem'


colMeans(is.na(rev4)) * 100
rev4$city<-'SD'
rev4 <- na.omit(rev4)

#Combine all data
rev <- rbind(rev1,rev2,rev3,rev4)
colMeans(is.na(rev)) * 100
write.csv(rev,'Reviews.csv',row.names = FALSE)

####################################Listing data##################################

list1<- read.csv('Los Angeleslistings.csv')
list2<- read.csv('Portlandlistings.csv')
list3<- read.csv('Salemlistings.csv')
list4<- read.csv('SDlistings.csv')

colnames(list1)
colnames(list2)
colnames(list3)
colnames(list4)

list1$city<-'LA'
list2$city<-'Portland'
list3$city<-'Salem'
list4$city<-'SD'

#Combine all data, since we are not using most of the columns in 
#listing data with NAs we leave it as it is.
colMeans(is.na(list1)) * 100
colMeans(is.na(list2)) * 100
colMeans(is.na(list3)) * 100
colMeans(is.na(list4)) * 100

#Combine all data
list<- rbind(list1,list2,list3,list4)
colMeans(is.na(list)) * 100
write.csv(list,'Listing.csv',row.names = FALSE)


####################################Neighborhood data##################################

n1 <- read.csv('Los Angelesneighbourhoods.csv')
n2 <- read.csv('Portlandneighbourhoods.csv')
n3 <- read.csv('Salemneighbourhoods.csv')
n4 <- read.csv('SDneighbourhoods.csv')

colnames(n1)
colnames(n2)
colnames(n3)
colnames(n4)

n1$city<-'LA'
n2$city<-'Portland'
n3$city<-'Salem'
n4$city<-'SD'

#Check NAs, we remove enitre neighbourhood_group column as it is empty
colMeans(is.na(n1)) * 100
colMeans(is.na(n2)) * 100
colMeans(is.na(n3)) * 100
colMeans(is.na(n4)) * 100

n1<- n1[colnames(n1)!='neighbourhood_group']
n2<- n2[colnames(n2)!='neighbourhood_group']
n3<- n3[colnames(n3)!='neighbourhood_group']
n4<- n4[colnames(n4)!='neighbourhood_group']

#Combine all data
n<- rbind(n1,n2,n3,n4)
colMeans(is.na(n)) * 100
write.csv(n,'Neighborhood.csv',row.names = FALSE)