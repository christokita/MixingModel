##################################################
#
# Threshold Probability of Performance 
#
##################################################


####################
# Seed task thresholds
####################
seedThresholds <- function(n, m, ThresholdMeans = NULL, ThresholdSDs = NULL) {
  # Loop through tasks and sample thresholds from normal dist
  threshMat <- lapply(1:length(ThresholdMeans), function(i) {
    threshList <- rtnorm(n = n, 
                         mean = ThresholdMeans[i], 
                         sd = ThresholdSDs[i], 
                         lower = 0)
    return(threshList)
  })
  threshMat <- do.call("cbind", threshMat)
  # Fix names
  colnames(threshMat) <- paste0("Thresh", 1:length(ThresholdMeans))
  rownames(threshMat) <- paste0("v-", 1:n)
  # Return
  return(threshMat)
}


####################
# Threshold function
####################
threshProb <- function(s, phi, nSlope) {
  T_vi <- (s^nSlope) / (s^nSlope + phi^nSlope)
}


####################
# Calculate Threshold
####################
calcThresholdProbMat <- function(TimeStep, ThresholdMatrix, StimulusMatrix, nSlope) {
  # select proper stimulus for this time step
  stimulusThisStep <- StimulusMatrix[TimeStep, ]
  # calculate threshold probabilities for one individual
  thresholdP <- lapply(1:nrow(ThresholdMatrix), function(i) {
    # select row for individual in threshold matrix
    indThresh <- ThresholdMatrix[i, ]
    # create task vector to be output and bound
    taskThresh <- rep(NA, length(indThresh))
    # loop through each task within individual
    for (j in 1:length(taskThresh)) {
      taskThresh[j] <- threshProb(s = stimulusThisStep[j], phi = indThresh[j], nSlope = nSlope)
    }
    return(taskThresh)
  })
  # bind and return
  thresholdP <- do.call("rbind", thresholdP)
  thresholdP[is.na(thresholdP)] <- 0 #fix NAs where thresh was 0 and stim was 0
  colnames(thresholdP) <- paste0("ThreshProb", 1:ncol(thresholdP))
  rownames(thresholdP) <- paste0("v-", 1:nrow(thresholdP))
  return(thresholdP)
}

####################
# Calculate Threshold
####################
calcThresholdProbMat_diffEta <- function(TimeStep, ThresholdMatrix, StimulusMatrix, nSlopeMatrix) {
  # select proper stimulus for this time step
  stimulusThisStep <- StimulusMatrix[TimeStep, ]
  # calculate threshold probabilities for one individual
  thresholdP <- lapply(1:nrow(ThresholdMatrix), function(i) {
    # select row for individual in threshold matrix
    indThresh <- ThresholdMatrix[i, ]
    # create task vector to be output and bound
    taskThresh <- rep(NA, length(indThresh))
    # Get eta
    eta <- nSlopeMatrix[i, 1]
    # loop through each task within individual
    for (j in 1:length(taskThresh)) {
      taskThresh[j] <- threshProb(s = stimulusThisStep[j], phi = indThresh[j], nSlope = eta)
    }
    return(taskThresh)
  })
  # bind and return
  thresholdP <- do.call("rbind", thresholdP)
  thresholdP[is.na(thresholdP)] <- 0 #fix NAs where thresh was 0 and stim was 0
  colnames(thresholdP) <- paste0("ThreshProb", 1:ncol(thresholdP))
  rownames(thresholdP) <- paste0("v-", 1:nrow(thresholdP))
  return(thresholdP)
}


####################
# Output Threshold Demands
####################
calcThresholdDetermMat <- function(TimeStep, ThresholdMatrix, StimulusMatrix) {
  # select proper stimulus for this time step
  stimulusThisStep <- StimulusMatrix[TimeStep, ]
  # calculate threshold probabilities for one individual
  thresholdP <- lapply(1:nrow(ThresholdMatrix), function(i) {
    # select row for individual in threshold matrix
    indThresh <- ThresholdMatrix[i, ]
    # create task vector to be output and bound
    taskThresh <- rep(0, length(indThresh))
    # loop through each task within individual
    for (j in 1:length(taskThresh)) {
      stim <- stimulusThisStep[j]
      thresh <- indThresh[j]
      if (stim > thresh) {
        taskThresh[j] <- 1
      }
    }
    return(taskThresh)
  })
  # bind and return
  thresholdP <- do.call("rbind", thresholdP)
  colnames(thresholdP) <- paste0("ThreshProb", 1:ncol(thresholdP))
  rownames(thresholdP) <- paste0("v-", 1:nrow(thresholdP))
  return(thresholdP)
}


