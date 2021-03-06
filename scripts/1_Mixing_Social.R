################################################################################
#
# Model incorporating both thresholds and network dynamics
#
################################################################################

rm(list = ls())
source("scripts/util/__Util__MASTER.R")

file_name <- "DifferentAlphas_BothTasksDiff"

####################
# Set global variables
####################
# Initial paramters: Free to change
# Base parameters
Ns             <- c(4, 16) #vector of number of individuals to simulate
m              <- 2 #number of tasks
gens           <- 10000 #number of generations to run simulation 
corrStep       <- 200 #number of time steps for calculation of correlation 
reps           <- 1 #number of replications per simulation (for ensemble) !!Change!!

# Threshold Parameters
mixes          <- c("A", "B", "AB")
A_ThreshM      <- c(10, 10) #population threshold means for clone line A !!Change!!
A_ThreshSD     <- A_ThreshM * 0.1 #population threshold standard deviations for clone line A !!Change!!
B_ThreshM      <- c(10, 10) #population threshold means for clone line B !!Change!!
B_ThreshSD     <- B_ThreshM * 0.1 #population threshold standard deviations for clone line B !!Change!!
InitialStim    <- c(0, 0) #intital vector of stimuli
deltas         <- c(0.6, 0.6) #vector of stimuli increase rates  
threshSlope    <- 7 #exponent parameter for threshold curve shape
alpha          <- m
A_alpha        <- c(m, m) #efficiency of task performance
B_alpha        <- c(m, m)
quitP          <- 0.2 #probability of quitting task once active !!Change!!

# Social Network Parameters
p              <- 1 #baseline probablity of initiating an interaction per time step
epsilon        <- 0.01 #relative weighting of social interactions for adjusting thresholds
beta           <- 1.1 #probability of interacting with individual in same state relative to others


####################
# Run simulation multiple times
####################
# Prep meta-lists for collection of group size simulations
groups_taskDist  <- list()
groups_taskCorr  <- list()
groups_taskStep  <- list()
groups_taskTally <- list()
groups_stim      <- list()
groups_entropy   <- list()


# Loop through group sizes
for (i in 1:length(Ns)) {
  
  # Set group size
  n <- Ns[i]
  
  # Loop through clonals mixes
  mix_taskDist <- list()
  mix_taskCorr <- list()
  
  for (mix_index in 1:length(mixes)) {
    
    # Set mix
    mix <- mixes[mix_index]
    
    # Set stim levels (for different larvae)
    # if (mix == "A") {
    #   StimRates      <- c(0.6, 0.6)
    # } else if (mix == "AB") {
    #   StimRates      <- c(0.6, 0.6) * 1.3
    # } else if (mix == "B") {
    #   StimRates      <- c(0.6, 0.6) * 1.4
    # }
    
    # Set work efficiency by lines
    if (mix == "A") {
      alpha      <- matrix(rep(A_alpha, n), ncol = m)
    } else if (mix == "AB") {
      input      <- c( rep(A_alpha, n/2), rep(B_alpha, n/2) ) 
      alpha      <- matrix(input, ncol = m, byrow = T)
    } else if (mix == "B") {
      alpha      <- matrix(rep(B_alpha, n), ncol = m)
    }
    
    # Prep lists for collection of simulation outputs
    ens_taskDist  <- list()
    ens_taskCorr  <- list()
    ens_taskStep  <- list()
    ens_taskTally <- list()
    ens_entropy   <- list()
    ens_stim      <- list()
    
    # Run Simulations
    for (sim in 1:reps) {
      # Set initial probability matrix (P_g)
      P_g <- initiateProbMatrix(n = n, m = m)
      
      # Seed task (external) stimuli
      stimMat <- seedStimuls(InitialSVector = InitialStim, 
                             gens = gens)
      
      # Seed internal thresholds
      if (mix == "A") {
        threshMat <- seedThresholds(n = n, 
                                    m = m, 
                                    ThresholdMeans = A_ThreshM, 
                                    ThresholdSDs = A_ThreshSD)
        rownames(threshMat) <- paste0("A-", rownames(threshMat))
      } else if(mix == "B") {
        threshMat <- seedThresholds(n = n, 
                                    m = m, 
                                    ThresholdMeans = B_ThreshM, 
                                    ThresholdSDs = B_ThreshSD)
        rownames(threshMat) <- paste0("B-", rownames(threshMat))
      } else if(mix == "AB") {
        threshMatA <- seedThresholds(n = n / 2, 
                                     m = m, 
                                     ThresholdMeans = A_ThreshM, 
                                     ThresholdSDs = A_ThreshSD)
        rownames(threshMatA) <- paste0("A-", rownames(threshMatA))
        threshMatB <- seedThresholds(n = n / 2, 
                                     m = m, 
                                     ThresholdMeans = B_ThreshM, 
                                     ThresholdSDs = B_ThreshSD)
        rownames(threshMatB) <- paste0("B-", rownames(threshMatB))
        threshMat <- rbind(threshMatA, threshMatB)
        rm(threshMatA, threshMatB)
      }
      
      # Start task performance
      X_g <- matrix(data = rep(0, length(P_g)), ncol = ncol(P_g))
      
      # Create cumulative task performance matrix
      X_tot <- X_g
      
      # Create cumulative adjacency matrix
      g_tot <-  matrix(data = rep(0, n * n), ncol = n)
      colnames(g_tot) <- paste0("v-", 1:n)
      rownames(g_tot) <- paste0("v-", 1:n)
      
      # Prep correlation step matrix
      X_prev <- matrix(data = rep(0, n * m), ncol = m)
      X_prevTot <- matrix(data = rep(0, n * m), ncol = m)
      taskCorr <- list()
      taskStep <- list()
      taskTally <- list()
      
      ####################
      # Simulate
      ####################
      # Run simulation
      for (t in 1:gens) {
        # Update stimuli
        stimMat <- update_stim(stim_matrix = stimMat, 
                               deltas = deltas, 
                               alpha = alpha, 
                               state_matrix = X_g, 
                               time_step = t)
        # Calculate task demand based on global stimuli
        P_g <- calcThresholdProbMat(TimeStep = t + 1, # first row is generation 0
                                    ThresholdMatrix = threshMat, 
                                    StimulusMatrix = stimMat, 
                                    nSlope = threshSlope)
        # Update task performance
        X_g <- updateTaskPerformance(P_sub_g    = P_g,
                                     TaskMat    = X_g,
                                     QuitProb   = quitP)
        
        # Capture current task performance tally
        tally <- matrix(c(t, colSums(X_g)), ncol = ncol(X_g) + 1)
        colnames(tally) <- c("t", colnames(X_g))
        tally <- transform(tally, Inactive = n - sum(X_g), n = n, replicate = sim)
        taskTally[[t]] <- tally
        
        # Update social network (previously this was before probability/task update)
        g_adj <- temporalNetwork(X_sub_g = X_g,
                                 p = p,
                                 bias = beta)
        g_tot <- g_tot + g_adj
        
        # Adjust thresholds
        threshMat <- adjust_thresholds_social_capped(social_network = g_adj,
                                                     threshold_matrix = threshMat,
                                                     state_matrix = X_g,
                                                     epsilon = epsilon,
                                                     threshold_max = 20)
        
        # Update total task performance profile
        X_tot <- X_tot + X_g
        
        # Create time step for correlation
        if (t %% corrStep == 0) {
          # Get tasks performance in correlation step
          X_step <- X_tot - X_prevTot
          # Add to ensemble list of task steps
          taskStep[[t / corrStep]] <- X_step
          # Calculate rank correlation if it is not the first step
          if(sum(X_prev) != 0) {
            # Normalize
            stepNorm <- X_step / rowSums(X_step)
            prevNorm <- X_prev / rowSums(X_prev)
            # Calculate ranks
            step_ranks <- calculateTaskRank(TaskStepMat = X_step)
            prev_ranks <- calculateTaskRank(TaskStepMat = X_prev)
            # Calculate Correlation
            rankCorr <- cor(prev_ranks, step_ranks, method = "spearman")
            # Put in list
            taskCorr[[(t / corrStep) - 1]] <- diag(rankCorr)
            names(taskCorr)[(t / corrStep) - 1] <- paste0("Gen", t)
          }
          # Update previous step total matrix
          X_prevTot <- X_tot
          # Update previous step total matrix
          X_prev <- X_step
        }
      }
      
      # Calculate Entropy
      # entropy <- mutualEntropy(TotalStateMat = X_tot)
      # entropy <- transform(entropy, n = n, replicate = sim)
      
      # Calculate total task distribution
      # totalTaskDist <- X_tot / rowSums(X_tot)
      totalTaskDist <- X_tot / gens
      totalTaskDist <- transform(totalTaskDist, Inactive = gens - rowSums(X_tot), 
                                 n = n, 
                                 replicate = sim, 
                                 Line = rownames(threshMat),
                                 Mix = mix)
      totalTaskDist$Line <- gsub("([A-Z]).*", "\\1", totalTaskDist$Line)
      
      # Create tasktally table
      # taskTally <- do.call("rbind", taskTally)
      
      # Create tasktally table
      # stimMat <- transform(stimMat, n = n, replicate = sim)
      
      # Add total task distributions, entropy values, and graphs to lists
      ens_taskDist[[sim]]  <- totalTaskDist
      ens_taskCorr[[sim]]  <- taskCorr
      # ens_entropy[[sim]]   <- entropy
      # ens_taskTally[[sim]] <- taskTally
      # ens_taskStep[[sim]]  <- taskStep
      # ens_stim[[sim]]      <- stimMat
      
      # Print simulation completed
      print(paste0("DONE: Mix = ", mix,  ", N = ", n, ", Simulation ", sim))
    }
    
    # Calculate mean correlation for each n
    runCorrs <- lapply(ens_taskCorr, function(x) {
      # Unlist
      runs <- do.call("rbind", x)
      # Calculate mean
      runMean <- matrix(data = rep(NA, m), ncol =  m)
      for (column in 1:m) {
        runMean[ , column] <- mean(runs[ , column], na.rm = TRUE)
      }
      colnames(runMean) <- colnames(runs)
      return(runMean)
    })
    runCorrs <- do.call("rbind", runCorrs)
    runCorrs <- transform(runCorrs, n = n, Mix = mix)
    
    # Add to list of lists
    mix_taskDist[[mix_index]]  <- ens_taskDist
    mix_taskCorr[[mix_index]]  <- runCorrs
    # groups_taskStep[[i]]  <- ens_taskStep
    # groups_taskTally[[i]] <- ens_taskTally
    # groups_stim[[i]]      <- ens_stim
    # groups_entropy[[i]]   <- ens_entropy
    
  }
  
  groups_taskDist[[i]]  <- mix_taskDist
  groups_taskCorr[[i]]  <- mix_taskCorr
}
  
# Bind and process
task_dist <- unlist(groups_taskDist, recursive = FALSE)
task_dist <- unlist(task_dist, recursive = FALSE)
task_dist <- do.call("rbind", task_dist)

task_corr <- unlist(groups_taskCorr, recursive = FALSE)
task_corr <- do.call("rbind", task_corr)


####################
# Save run
####################
# save(task_dist, task_corr, file = paste0("output/Rdata/", file_name, ".Rdata"))



