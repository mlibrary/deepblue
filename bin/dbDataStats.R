rm(list=ls())
data <- read.csv(file.choose())

head(data)

data$Create.date
cleanData <- data


cleanData$Create.date <- gsub('(\\d{4})(\\d{2})(\\d{2})(\\s\\d{6})', '\\1-\\2', data$Create.date)
cleanData$Published.date <- gsub('(\\d{4})(\\d{2})(\\d{2})(\\s\\d{6})', '\\1-\\2', data$Published.date)
head(cleanData)

pubMonth <- sort(unique(cleanData$Published.date), decreasing = F)
pubMonth <- pubMonth[-1]
createMonth <- sort(unique(cleanData$Create.date), decreasing = F)

pubPerMonth <- rep(0, length(pubMonth))
createPerMonth <- pubPerMonth

pubTotal <- pubPerMonth
createTotal <- pubPerMonth

disTitles <- c('Arts','ArtsCreate', 'Business','BusinessCreate','Engineering','EngineeringCreate','General Information Services','General Information ServicesCreate', 'Government, Politics, and Law', 'Government, Politics, and LawCreate','Health Sciences','Health SciencesCreate', 'Humanities', 'HumanitiesCreate','International Studies','International StudiesCreate', 'News and Current Events', 'News and Current EventsCreate','Science', 'ScienceCreate','Social Sciences','Social SciencesCreate', 'Other', 'OtherCreate')
disDF <- matrix(data=0, nrow=length(pubMonth), ncol=length(disTitles), dimnames=list(x=pubMonth, y=disTitles))
runningTotals <- data.frame( pubTotal, createTotal, disDF, row.names=pubMonth)
dis <- c('Arts','Business','Engineering','General Information Services', 'Government, Politics, and Law', 'Health Sciences', 'Humanities', 'International Studies', 'News and Current Events', 'Science', 'Social Sciences', 'Other')



for (i in 1:length(pubMonth)){
  tempPub <- cleanData[grep(pubMonth[i], cleanData$Published.date), ]
  tempCreate <- cleanData[grep(pubMonth[i], cleanData$Create.date), ]
  pubPerMonth[i] <- length(grep(pubMonth[i], cleanData$Published.date))
  createPerMonth[i] <- length(grep(pubMonth[i], cleanData$Create.date))
  

  if(i==1){
    runningTotals[i, 1] <- pubPerMonth[i]
    runningTotals[i, 2] <- createPerMonth[i]
    for (ii in 1:length(dis)){
      iii <- ii*2-1+2
      runningTotals[i,iii] <- length(grep(dis[ii], tempPub$Discipline))
      runningTotals[i,iii+1] <- length(grep(dis[ii], tempCreate$Discipline))
      }
    
  }else{
    runningTotals[i, 1] <- runningTotals[i-1, 1] + pubPerMonth[i]
    runningTotals[i,2] <- runningTotals[i-1, 2] + createPerMonth[i]
    for (ii in 1:length(dis)){
      iii <- ii*2-1+2
      runningTotals[i,iii] <- runningTotals[i-1,iii] + length(grep(dis[ii], tempPub$Discipline)) 
      runningTotals[i,iii+1] <- runningTotals[i-1,iii+1] +length(grep(dis[ii], tempCreate$Discipline))
    }
  }
}

write.csv(runningTotals,'dbd_runningTotals.csv')
lab <- seq(1,nrow(runningTotals),12)
lab2 <- rownames(runningTotals)[1]
for(i in 2:length(lab)){
  lab2 <- append(lab2,rownames(runningTotals)[lab[i]])
}
lab2 <- c(lab2, '2025-04')
titles <- c('Total', dis)

range()


for(i in 1:length(titles)){
  ii <- i*2-1
  quartz.options(height=8, width=12)
  par(oma=c(4,2,0.5,1), mar=c(2,3,1.5,0))
  plot.new()

  plot(runningTotals[,ii], type='l', col='blue', xlab='', ylab='', main='', axes=F, xlim=c(0,110), ylim=c(0,1600))
  lines(runningTotals[,ii+1], col='red')
  axis(1, at=seq(1,109, by=12), labels = lab2,cex.axis=1, line=-0.8)
  axis(2, at=seq(0,1600, 100), line=-1.5)
  legend(1,1500, legend=c('Created', 'Published'), col=c('red', 'blue'), fill=c('red', 'blue'))
  mtext('Date (yyyy-mm)',1, line=3, adj=0.5,cex=2)
  mtext('Total (Thounsands)', 2, line=1.5, cex=2)
  mtext(paste('Deep Blue Data:', titles[i]), 3, line=-1, cex=2)
  dev.copy(pdf,paste(titles[i], 'overTime.pdf', sep=''))
  dev.off()
}



hs <- cleanData[grep('Health Sciences', cleanData$Discipline), ]

years <- seq(2019, 2024, by=1)

pub <- rep(0, length(years))
cre <- pub

hsYears <- data.frame(years, pub, cre)

for(i in 1:length(years)){
  hsYears[i, 2] <- length(grep(years[i], hs$Published.date))
  hsYears[i, 3] <- length(grep(years[i], hs$Create.date))
}





dis <- c('Arts','Business','Engineering','General Information Services', 'Government, Politics, and Law', 'Health Sciences', 'Humanities', 'International Studies', 'News and Current Events', 'Science', 'Social Sciences', 'Other')
rawDis <- unique(cleanData$Discipline)


grep('Science', rawDis)


disTotal <- rep(0,length(dis))
for (i in 1:length(dis)){
  disTotal[i] <- length(grep(dis[i],cleanData$Discipline))
}

disData <- as.data.frame(cbind(dis,disTotal), row.names = NULL, optional = FALSE,
                         cut.names = FALSE, col.names = dis, fix.empty.names = TRUE,
                         check.names = !optional,
                         stringsAsFactors = FALSE)
write.csv(disData,'DisTotals.csv')
barplot(height=as.numeric(disData$disTotal), axes=F, width=2, xlim=c(0,16))
axis(1, at=seq(0,16, by=0.5))

labels = disData$dis, hadj=1, padj=0.5
axis(1)



ran <- 2019:2024
titles <- c('pubTotal','createTotal','Arts','ArtsCreate', 'Business','BusinessCreate','Engineering','EngineeringCreate','General Information Services','General Information ServicesCreate', 'Government, Politics, and Law', 'Government, Politics, and LawCreate','Health Sciences','Health SciencesCreate', 'Humanities', 'HumanitiesCreate','International Studies','International StudiesCreate', 'News and Current Events', 'News and Current EventsCreate','Science', 'ScienceCreate','Social Sciences','Social SciencesCreate', 'Other', 'OtherCreate')
yearlyDF <- matrix(data=0, nrow=length(ran), ncol=length(disTitles), dimnames=list(x=ran, y=disTitles))
for(i in 1:length(ran)){
  loc <- grep(ran[i], rownames(runningTotals))
  for (ii in 1:ncol(yearlyDF)){
    yearlyDF[i,ii] <- runningTotals[loc[length(loc)], ii] - runningTotals[loc[1]-1, ii]
  }
}
write.csv(yearlyDF, 'yearlyDeposits')


titles <- c('pubTotal','createTotal','Arts','ArtsCreate', 'Business','BusinessCreate','Engineering','EngineeringCreate','General Information Services','General Information ServicesCreate', 'Government, Politics, and Law', 'Government, Politics, and LawCreate','Health Sciences','Health SciencesCreate', 'Humanities', 'HumanitiesCreate','International Studies','International StudiesCreate', 'News and Current Events', 'News and Current EventsCreate','Science', 'ScienceCreate','Social Sciences','Social SciencesCreate', 'Other', 'OtherCreate')
monthlyDeposits <- matrix(data=0, nrow=nrow(runningTotals), ncol=length(disTitles), dimnames=list(x=rownames(runningTotals), y=disTitles))
ran <- grep('2019-01', rownames(runningTotals))

for(i in ran:length(rownames(runningTotals))){
  for (ii in 1:ncol(yearlyDF)){
    monthlyDeposits[i,ii] <- runningTotals[i, ii] - runningTotals[i-1, ii]
  }
}

write.csv(monthlyDeposits[-(1:ran-1),], 'monthyDeposits.csv'
          