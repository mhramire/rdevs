save.list.plots.pdf <- function(list.plots, name, ...){
  
  library(plyr)
  
  pdf(file = name, ...)
  
  l_ply(list.plots, print)
  
  dev.off()
  
}

plot_bar <- function(variable, show.values = TRUE, sort.by.count = TRUE, color = "darkred", transpose = FALSE){
  require(ggplot2)
  require(plyr)
  # Remeberber kid, this function depends on 'freqtable' function.
  variable <- ifelse(is.na(variable), "NA", variable)
  t1 <- freqtable(variable, sort.by.count=sort.by.count, add.total=FALSE)
  t2 <- freqtable(variable, sort.by.count=sort.by.count, add.total=FALSE, pretty=TRUE)
  names(t2)[2:5] <- paste("label", names(t2)[2:5], sep="_")
  
  t <- join(t1, t2)
  t$variable <- factor(t$category, levels=t1$category)
  t$id <- seq(nrow(t))
  
  p <- ggplot(t, aes(x = variable)) +
    geom_bar(aes(y = relfreq), stat="identity", fill = "darkred") +
    scale_y_continuous(labels = percent_format())
    
  if(show.values){
    p <- p + scale_y_continuous(labels = percent_format(), limits = c(0,max(t$relfreq)+.1))
    if(transpose){
      p <- p + geom_text(aes(id, relfreq, label = label_freq), size = 4, hjust = -.1, vjust = 0)
      p <- p + geom_text(aes(id, relfreq, label = label_relfreq), size = 4, hjust = -1.5, vjust = 0)
      p
    } else {
      p <- p + geom_text(aes(id, relfreq, label = label_relfreq), size = 4, hjust = .5, vjust = -2.5)                            
      p <- p + geom_text(aes(id, relfreq, label = label_freq), size = 3.8, hjust = .5, vjust = -1)
      
    }   
  }
  
  if(transpose) p <- p + coord_flip()
  
  p <- p + ylab(NULL) + xlab(NULL)
  
  return(p)
}

plot_pie <- function(variable){
  require(ggplot2)
  data <- data.frame(variable=factor(variable))
  ggplot(data, aes(x = factor(1), fill = variable)) + geom_bar(width = 1) + 
    coord_polar(theta = "y") + 
    xlab(NULL) +  theme(axis.ticks = element_blank(), axis.text = element_blank())
}


plot_dist_pres <- function (variable, indicator, coord.flip = FALSE, count.labels = FALSE, 
                            indicator.labels = FALSE, sort.by = c("other", "variable", "indicator"), 
                            abline = FALSE, size.text = 4, size.text2 = 10, remove.axis.y = TRUE, bar.width = 0.6,Hjust=0) {
  require(plyr)
  require(dplyr)
  require(ggplot2)
  require(scales)
  
  t <- table_bivariate(variable, indicator)
  if (sort.by[1] == "indicator") {
    if (coord.flip) 
      t <- t %.% arrange(desc(-indicator.mean))
    else t <- t %.% arrange(desc(indicator.mean))
  }
  else if (sort.by[1] == "variable") {
    if (coord.flip) 
      t <- t %.% arrange(desc(-freq))
    else t <- t %.% arrange(desc(freq))
  }
  t$variable <- factor(t$variable, levels = t$variable)
  t$id <- seq(nrow(t))
  p <- ggplot(t) + geom_bar(aes(variable, percent), stat = "identity", 
                            fill = "gray80", width = bar.width) + geom_line(aes(id, 
                                                                                indicator.mean), colour = "darkred") + geom_point(aes(id, 
                                                                                                                                      indicator.mean), colour = "darkred")
  if (coord.flip) 
    p <- p + coord_flip()
  if (count.labels) 
    if (coord.flip) 
      p <- p + geom_text(aes(variable, percent, label = freq.pretty), 
                         size = size.text, hjust = Hjust, colour = "black")
  else p <- p + geom_text(aes(variable, percent, label = freq.pretty), 
                          size = size.text, vjust = 1.5, colour = "black")
  if (indicator.labels) 
    if (coord.flip) 
      p <- p + geom_text(aes(variable, indicator.mean, 
                             label = indicator.mean.pretty), size = size.text, 
                         hjust = -1, colour = "darkred")
  else p <- p + geom_text(aes(variable, indicator.mean, 
                              label = indicator.mean.pretty), size = size.text, 
                          vjust = -0.5, colour = "darkred")
  p <- p + ylim(0, max(c(t$percent, t$indicator.mean)) * 1.1)
  p <- p + theme(text = element_text(size = 10), title = element_text(hjust = 0), 
                 axis.title.x = element_text(hjust = 0.5), axis.title.y = element_text(hjust = 0.5), 
                 axis.text = element_text(size = size.text2), panel.grid = element_blank(), 
                 panel.border = element_blank(), panel.background = element_blank(), 
                 legend.position = "bottom", legend.title = element_blank())
  if (remove.axis.y) 
    if (coord.flip) 
      p <- p + theme(axis.text.x = element_blank(),axis.text.y=element_text(colour="black"), axis.ticks.x = element_blank())
  else p <- p + theme(axis.text.y = element_blank(),axis.text.x=element_text(colour="black"), axis.ticks.y = element_blank())
  else p <- p + scale_y_continuous(labels = percent)
  p <- p + xlab(NULL) + ylab(NULL)
  p
}


plot_pareto <- function(variable, prop = TRUE, ...){
  require(ggplot2)
  t <- freqtable(variable, sort.by.count=TRUE, add.total=FALSE)
  t$variable <- factor(t$variable, levels=t$variable)
  t$id <- seq(nrow(t))
  
  ggplot(t) + 
    geom_bar(aes(x=variable, y=relfreq), stat = "identity") +
    geom_line(aes(x=id, y=cumrelfreq)) + 
    geom_point(aes(x=id, y=cumrelfreq)) + 
    scale_y_continuous(labels = percent_format()) +
    xlab(NULL) + ylab(NULL)
  
}


plot_dist <- function(variable, indicator,  facet){
  require(ggplot2)
  require(scales)
  
  if(!is.numeric(variable) & any(is.na(variable))){
    if(is.factor(variable)){
      lvls <- c(levels(variable), "NA")
      variable <- as.character(variable)
      variable <- ifelse(is.na(variable), "NA", variable)
      variable <- factor(variable, levels=lvls, ordered=TRUE)
    } else {
      variable <- ifelse(is.na(variable), "NA", variable)  
    }
  }
  
  if(is.numeric(variable) & length(unique(variable))<=10){
    variable <- as.character(variable)
    variable <- ifelse(is.na(variable), "NA", variable)
  }
  
  df <- data.frame(variable = variable)
  if(!missing(indicator)) df <- cbind(df, indicator = indicator)
  if(!missing(facet)) df <- cbind(df, facet = facet)
  
  p <- ggplot(df) +  geom_bar(aes(variable, ..count../sum(..count..)))
  
  if(!missing(indicator)){
    if(is.numeric(variable)){
      p <- p + stat_smooth(aes(x=variable,y=indicator), color ="darkred", method = "loess",span=0.99, se=FALSE)
    } else{
      p <- p +
        stat_summary(aes(x=variable,y=indicator), fun.y=mean, colour="red", geom="point") +
        stat_summary(aes(x=variable,y=indicator, group = 1), fun.y=mean, colour="darkred", geom="line")
    }
  }
  
  if(!missing(facet)){
    p <- p + facet_grid(. ~ facet, scales="free")
  }
  
  p <- p + xlab(NULL) + ylab(NULL) + scale_y_continuous(labels = percent)
  
  return(p)
}


plot_dist2 <- function (variable, indicator, facet, num_unique = 10) {
  require(ggplot2)
  require(scales)
  if (!is.numeric(variable) & any(is.na(variable))) {
    if (is.factor(variable)) {
      lvls <- c(levels(variable), "NA")
      variable <- as.character(variable)
      variable <- ifelse(is.na(variable), "NA", variable)
      variable <- factor(variable, levels = lvls, ordered = TRUE)
    }
    else {
      variable <- ifelse(is.na(variable), "NA", variable)
    }
  }
  if (is.numeric(variable) & length(unique(variable)) <= num_unique) {
    variable <- as.character(variable)
    variable <- ifelse(is.na(variable), "NA", variable)
  }
  df <- data.frame(variable = variable)
  if (!missing(indicator)) 
    df <- cbind(df, indicator = indicator)
  if (!missing(facet)) 
    df <- cbind(df, facet = facet)
  p <- ggplot(df) + geom_bar(aes(variable, ..count../sum(..count..)),fill = "gray80")
  if (!missing(indicator)) {
    if (is.numeric(variable)) {
      p <- p + stat_smooth(aes(x = variable, y = indicator), 
                           color = "darkred", method = "loess", span = 0.99, 
                           se = FALSE)
    }
    else {
      p <- p + stat_summary(aes(x = variable, y = indicator), 
                            fun.y = mean, colour = "red", geom = "point") + 
        stat_summary(aes(x = variable, y = indicator, 
                         group = 1), fun.y = mean, colour = "darkred", 
                     geom = "line")
    }
  }
  if (!missing(facet)) {
    p <- p + facet_grid(. ~ facet, scales = "free")
  }
  p <- p + xlab(NULL) + ylab(NULL) + scale_y_continuous(labels = percent)+
    theme(text = element_text(size = 10),panel.grid = element_blank(),
          panel.border = element_blank(), panel.background = element_blank(),
          legend.position = "bottom", legend.title = element_blank())
  
  return(p)
}

