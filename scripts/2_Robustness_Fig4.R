################################################################################
#
# Script for Fig. 4 in MS
# 
################################################################################

rm(list = ls())
source("scripts/util/__Util__MASTER.R")
library(scales)
library(RColorBrewer)

#######################
# Set parameter range #
#######################

# Robustness check
# mu_sweep    <- seq(10, 20, by = 1) # range of AThreshM
# alpha_sweep <- seq(2, 7, by = 0.5)  # range of Aalpha
# mu_sweep    <- seq(10, 20, by = 1) # range of AThreshM
# alpha_sweep <- seq(2, 7, by = 0.5)  # range of Aalpha
###### NEW 012120
mu_sweep    <- seq(6.5, 15.5, by = 0.5) # range of AThreshM
alpha_sweep <- seq(1.25, 5.75, by = 0.25)  # range of Aalpha

params        <- matrix(data = NA, nrow = length(mu_sweep)*length(alpha_sweep), ncol = 10)
params[,3:4]  <- 2    # efficiency of A
params[,5:6]  <- 0.6  # demand rate
params[,9:10] <- 10   # mean threshold of A

# Fill in params matrix
for(i in 1:nrow(params)){
  params[i,7:8] <- mu_sweep[(i-1)%/%length(alpha_sweep)+1]
  params[i,1:2] <- alpha_sweep[((i-1)%%length(alpha_sweep)+1)]
}

# mu_sweep    <- seq(6, 16, by = 0.5) # range of AThreshM
# alpha_sweep <- seq(1, 6, by = 0.25)  # range of Aalpha

# Prep matrix for storing
robustcheck <- as.data.frame(params)
colnames(robustcheck) <- c('Calpha1','Calpha2','Dalpha1','Dalpha2','delta1','delta2','Cmu1','Cmu2','Dmu1','Dmu2')
robustcheck['amps'] <- numeric(0)

######################################################
# Load data & compute deg of amplification/contagion #
######################################################

for (INDEX in 1:nrow(params)){
  
    ####################
    # select data
    ####################

    # Initial paramters: Free to change
    # Base parameters
    Ns             <- c(16) #vector of number of individuals to simulate
    m              <- 2 #number of tasks
    gens           <- 10000 #number of generations to run simulation 
    corrStep       <- 200 #number of time steps for calculation of correlation 
    reps           <- 10 #number of replications per simulation (for ensemble) !!Change!!
    
    # Threshold Parameters
    mixes          <- c("A", "B", "AB")
    A_ThreshM      <- c(params[INDEX,7], params[INDEX,8]) #population threshold means for clone line A !!Change!!
    A_ThreshSD     <- A_ThreshM * 0.1 #population threshold standard deviations for clone line A !!Change!!
    B_ThreshM      <- c(params[INDEX,9], params[INDEX,10]) #population threshold means for clone line B !!Change!!
    B_ThreshSD     <- B_ThreshM * 0.1 #population threshold standard deviations for clone line B !!Change!!
    InitialStim    <- c(0, 0) #intital vector of stimuli
    deltas         <- c(params[INDEX,5], params[INDEX,6]) #vector of stimuli increase rates  
    threshSlope    <- 7 #exponent parameter for threshold curve shape
    alpha          <- m
    # A_alpha        <- c(m, m*3) #efficiency of task performance
    # B_alpha        <- c(m*3, m)
    A_alpha        <- c(params[INDEX,1], params[INDEX,2])
    B_alpha        <- c(params[INDEX,3], params[INDEX,4])
    quitP          <- c(0.2, 0.2) #probability of quitting task once active !!Change!!

    file_name2 <- sprintf("N16only_AThreshM_%1.2f_%1.2f_AThreshSD_%1.2f_%1.2f_BThreshM_%1.2f_%1.2f_BThreshSD_%1.2f_%1.2f_deltas_%1.2f_%1.2f_threshSlope_%d_%d_Aalpha_%1.2f_%1.2f_Balpha_%1.2f_%1.2f_quitP_%1.2f_%1.2f",
                          A_ThreshM[1], A_ThreshM[2], A_ThreshSD[1]/A_ThreshM[1], A_ThreshSD[2]/A_ThreshM[2], 
                          B_ThreshM[1], B_ThreshM[2], B_ThreshSD[1]/B_ThreshM[1], B_ThreshSD[2]/B_ThreshM[2],
                          deltas[1], deltas[2], threshSlope, threshSlope, A_alpha[1], A_alpha[2], 
                          B_alpha[1], B_alpha[2], quitP[1], quitP[2])

    ####################
    # load data
    ####################
    load(paste0("output/Rdata/", file_name2, "_robust_50.Rdata"))
    # readRDS(paste0("output/Rdata/", file_name2, "_robust_50.Rdata"))

    ####################
    # process data
    ####################
    ## Prepare data
    task_dist <- task_dist %>% 
      group_by(n) %>% 
      mutate(set = paste0(Mix, "-", replicate)) %>% 
      mutate(set = factor(set, 
                          levels = c(paste("A", unique(replicate), sep = "-"),  
                                     paste("B", unique(replicate), sep = "-"),
                                     paste("AB", unique(replicate), sep = "-")) ))
    
    # Prepare means and SDs
    task_VarMean_byrepbyLine <- task_dist %>% # stats by replicate and Line
      group_by(n, Mix, replicate, Line, set) %>%
      summarise(SD1 = sd(Task1),
                SD2 = sd(Task2),
                Mean1 = mean(Task1),
                Mean2 = mean(Task2))
    
    task_VarMean_byrepABonly <- task_dist %>% # stats by replicate, mixed colonies only
      filter(Mix == "AB") %>%
      group_by(n, Mix, replicate, set) %>%
      summarise(SD1 = sd(Task1),
                SD2 = sd(Task2),
                Mean1 = mean(Task1),
                Mean2 = mean(Task2)) %>%
      mutate(Line = "Mixed")
    
    task_VarMean_byrep <- rbind(task_VarMean_byrepbyLine, task_VarMean_byrepABonly) %>% group_by(n, Mix)
    
    task_VarMean_byMixbyLine <- task_dist %>% # stats by Mix
      group_by(n, Mix, replicate, Line, set) %>%
      summarise(Mean1rep = mean(Task1),
                Mean2rep = mean(Task2)) %>%
      group_by(n, Mix, Line) %>%
      summarise(SD1 = sd(Mean1rep),
                SD2 = sd(Mean2rep),
                SE1 = sd(Mean1rep) / sqrt(length(Mean1rep)),
                SE2 = sd(Mean2rep) / sqrt(length(Mean2rep)),
                Mean1 = mean(Mean1rep),
                Mean2 = mean(Mean2rep))
    
    task_VarMean_byMixABonly <- task_dist %>% # stats by Mix, mixed colonies only
      filter(Mix == "AB") %>%
      group_by(n, Mix, replicate, set) %>%
      summarise(Mean1rep = mean(Task1),
                Mean2rep = mean(Task2)) %>%
      group_by(n, Mix) %>%
      summarise(SD1 = sd(Mean1rep),
                SD2 = sd(Mean2rep),
                SE1 = sd(Mean1rep) / sqrt(length(Mean1rep)),
                SE2 = sd(Mean2rep) / sqrt(length(Mean2rep)),
                Mean1 = mean(Mean1rep),
                Mean2 = mean(Mean2rep)) %>%
      mutate(Line = "Mixed")
    
    task_VarMean_byMix <- rbind(task_VarMean_byMixbyLine, task_VarMean_byMixABonly) %>% group_by(n, Mix)
    
    # !!! NEW !!! change 
    # 1) "Line" -> "Type"
    colnames(task_VarMean_byMix)[colnames(task_VarMean_byMix) == "Line"] <- "Type"
    colnames(task_VarMean_byrep)[colnames(task_VarMean_byrep) == "Line"] <- "Type"
    colnames(task_dist)[colnames(task_dist) == "Line"] <- "Type"
    
    # 2) Change category names
    task_VarMean_byMix$Type[task_VarMean_byMix$Type == "A"]  <- "Type X"
    task_VarMean_byMix$Type[task_VarMean_byMix$Type == "B"]  <- "Type Y"
    task_VarMean_byMix$Type[task_VarMean_byMix$Type == "AB"] <- "Mixed"
    
    task_VarMean_byMix$Mix <- as.character(task_VarMean_byMix$Mix)
    task_VarMean_byMix$Mix[task_VarMean_byMix$Mix == "A"]  <- "Type X"
    task_VarMean_byMix$Mix[task_VarMean_byMix$Mix == "B"]  <- "Type Y"
    task_VarMean_byMix$Mix[task_VarMean_byMix$Mix == "AB"] <- "Mixed"
    
    task_VarMean_byrep$Type[task_VarMean_byrep$Type == "A"]  <- "Type X"
    task_VarMean_byrep$Type[task_VarMean_byrep$Type == "B"]  <- "Type Y"
    task_VarMean_byrep$Type[task_VarMean_byrep$Type == "AB"] <- "Mixed"
    
    task_VarMean_byrep$Mix <- as.character(task_VarMean_byrep$Mix)
    task_VarMean_byrep$Mix[task_VarMean_byrep$Mix == "A"]  <- "Type X"
    task_VarMean_byrep$Mix[task_VarMean_byrep$Mix == "B"]  <- "Type Y"
    task_VarMean_byrep$Mix[task_VarMean_byrep$Mix == "AB"] <- "Mixed"
    
    task_dist$Type[task_dist$Type == "A"]  <- "Type X"
    task_dist$Type[task_dist$Type == "B"]  <- "Type Y"
    task_dist$Type[task_dist$Type == "AB"] <- "Mixed"
    
    task_dist$Mix <- as.character(task_dist$Mix)
    task_dist$Mix[task_dist$Mix == "A"]  <- "Type X"
    task_dist$Mix[task_dist$Mix == "B"]  <- "Type Y"
    task_dist$Mix[task_dist$Mix == "AB"] <- "Mixed"
    
    #########################
    # extract relevant data
    #########################
    X_pure    <- task_VarMean_byMix$Mean1[task_VarMean_byMix$Mix=="Type X" & task_VarMean_byMix$Type=="Type X"]
    Y_pure    <- task_VarMean_byMix$Mean1[task_VarMean_byMix$Mix=="Type Y" & task_VarMean_byMix$Type=="Type Y"]
    X_mix     <- task_VarMean_byMix$Mean1[task_VarMean_byMix$Mix=="Mixed" & task_VarMean_byMix$Type=="Type X"]
    Y_mix     <- task_VarMean_byMix$Mean1[task_VarMean_byMix$Mix=="Mixed" & task_VarMean_byMix$Type=="Type Y"]
    X_pure_SE <- task_VarMean_byMix$SE1[task_VarMean_byMix$Mix=="Type X" & task_VarMean_byMix$Type=="Type X"]
    Y_pure_SE <- task_VarMean_byMix$SE1[task_VarMean_byMix$Mix=="Type Y" & task_VarMean_byMix$Type=="Type Y"]
    X_mix_SE  <- task_VarMean_byMix$SE1[task_VarMean_byMix$Mix=="Mixed" & task_VarMean_byMix$Type=="Type X"]
    Y_mix_SE  <- task_VarMean_byMix$SE1[task_VarMean_byMix$Mix=="Mixed" & task_VarMean_byMix$Type=="Type Y"]
    
    #########################
    # compute and store deg of behavioral amplification / contagion ("amp")
    #########################
    # amp <- abs(Y_mix - X_mix) - abs(Y_pure - X_pure)
    
    # new definition
    if( X_pure < Y_pure ){
      amp <- (Y_mix - X_mix) - (Y_pure - X_pure)  
    }else if( X_pure > Y_pure ){
      amp <- (X_mix - Y_mix) - (X_pure - Y_pure) 
    }
    robustcheck[INDEX,'amps'] <- amp
    
    # if there is a 'flip' in order, record NaN; will appear as gray
    CIfactor <- 1.96
    
    if( X_pure < Y_pure ){
      if( (X_mix - X_mix_SE*CIfactor) > (Y_mix + Y_mix_SE*CIfactor) ){
        robustcheck[INDEX,'amps'] <- NaN
        # print("CASE1")
        # print(paste0(INDEX))
        # print(paste0(params[INDEX,]))
      }
    }else if( X_pure > Y_pure ){
      if( (Y_mix - Y_mix_SE*CIfactor) > (X_mix + X_mix_SE*CIfactor) ){
        robustcheck[INDEX,'amps'] <- NaN
        # print("CASE2")
        # print(paste0(INDEX))
        # print(paste0(params[INDEX,]))
      }
    }
    
}

#############
# Plot data #
#############
# robustcheck[is.na(robustcheck)] <- 0

# From Chris's code
myPalette <- colorRampPalette(brewer.pal(8, "YlOrRd"))
colPal <- c(myPalette(5), "#800026")
# colPal <- c("#7C217F", "white", "#EE751C")
# colPal <- c("#bd925a", "white", "#79a7ac")  # vik palette v1, update 2/2/20
colPal <- c("#A16928", "white", "#2887a1")  # vik palette v2, update 2/2/20

#Darker #A16928,#bd925a,#d6bd8d,#edeac2,#b5c8b8,#79a7ac,#2887a1 #Darker

colLim <- abs( c(max(robustcheck$amps), min(robustcheck$amps)) ) + 0.02
# colTitle <- expression(atop("Behavioral change",
#                             (paste("|",C[het]-D[het],"|"~-~"|",C[hom]-D[hom],"|"))))
colTitle <- "" # "Change in between-\ntype relative task\nperformance"

gg_amps <- ggplot() +
  theme_bw() +
  geom_tile(data   = robustcheck, 
            colour = "light gray",
            size   = 0.0000001,
            aes(x = Cmu1, y = Calpha1, fill = amps)) +  # flip order of axes
  scale_size(guide = 'none') +
  scale_y_continuous( # limits = c(min(alpha_sweep), max(alpha_sweep)),
                        breaks = seq(min(alpha_sweep), max(alpha_sweep), 0.5),
                        expand = c(0,0)) +
  scale_x_continuous( # limits = c(min(mu_sweep), max(mu_sweep)),
                        breaks = seq(min(mu_sweep), max(mu_sweep), 1),
                        expand = c(0,0)) +
  scale_fill_gradientn(name     = colTitle,
                       colours  = colPal,
                       na.value = "light gray", #909090",
                       # limits = c(-colLim, colLim),
                       limits   = c(-0.24, 0.24),
                       breaks   = seq(-0.2, 0.2, 0.1),
                       labels   = c("-0.2\nContagion", "-0.1", " 0.0", " 0.1", " 0.2\nAmplification"),
                       oob      = squish) +
  # ylab( expression("Task efficiency ("*alpha^X~"or"~alpha^Y*")") ) +
  ylab( expression("Task efficiency ("*alpha^X*")") ) +
  # xlab( expression("Mean task threshold ("*mu^X~"or"~mu^Y*")") ) +
  xlab( expression("Mean task threshold ("*mu^X*")") ) +
  theme(legend.key.height = unit(0.04, "npc"),
        legend.key.width  = unit(0.14, "npc"),
        legend.key        = element_rect(colour = "black", size = 0.5),
        legend.margin     = margin(t = 0, r = 0, b = 0, l = -0.02, "npc"),
        legend.text       = element_text(size = 5),
        legend.title      = element_text(size = 6),
        legend.background = element_rect(fill = "NA", size = 1),
        legend.position   = "top",
        axis.text.y       = element_text(size = 6, margin = margin(5, 2, 5, -2), color = "black"),
        axis.text.x       = element_text(size = 6, margin = margin(2, 5, -2, 5), color = "black"),
        axis.title        = element_text(size = 11, margin = margin(0, 0, 0, 0)),
        axis.ticks.length = unit(0, "cm"),
        panel.border      = element_rect(fill = "NA", size = 1)
        )

gg_amps 

# PNG
# # ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample.png"), width = 2.90, height = 2.10, units = "in",  dpi = 800)
# # ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_v2.png"), width = 2.90, height = 2.10, units = "in",  dpi = 800)
# # ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50.png"), width = 2.90, height = 2.10, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_temp2.png"), width = 2.50, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_v3.png"), width = 2.70, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_v4.png"), width = 2.55, height = 2.90, units = "in",  dpi = 800)

# # Vector
# # ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_temp.eps"), width = 2.90, height = 2.10, units = "in",  dpi = 800)
# # ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_temp.pdf"), width = 2.90, height = 2.10, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_temp2.eps"), width = 2.50, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_temp2.pdf"), width = 2.50, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_v3.pdf"), width = 2.70, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_v4.pdf"), width = 2.55, height = 2.90, units = "in",  dpi = 800)
# ggsave(filename = paste0("output/Parameter_exp/Parameter_space_sample_50_v5-5.pdf"), width = 2.55, height = 2.90, units = "in",  dpi = 1600)


