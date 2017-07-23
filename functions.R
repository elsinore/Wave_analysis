#################################
# WZY	Basic Functions Collection#
#################################
#===============================#
###################### Basic Functions for Data Manipulation
#=== Convert Object of Class "dist" into Data Frame in R ####
# User: A5C1D2H2I1M1N2O1R2T1 From:(https://stackoverflow.com/questions/23474729/convert-object-of-class-dist-into-data-frame-in-r)
WZY.convertDist <- function(inDist) {
  if (class(inDist) != "dist") stop("wrong input type")
  A <- attr(inDist, "Size")
  B <- if (is.null(attr(inDist, "Labels"))) sequence(A) else attr(inDist, "Labels")
  if (isTRUE(attr(inDist, "Diag"))) attr(inDist, "Diag") <- FALSE
  if (isTRUE(attr(inDist, "Upper"))) attr(inDist, "Upper") <- FALSE
  data.frame(
    row = B[unlist(lapply(sequence(A)[-1], function(x) x:A))],
    col = rep(B[-length(B)], (length(B)-1):1),
    value = as.vector(inDist))
}
####### Example: Input############################################
#            CONT       INTG       DMNR       DILG
# INTG 0.56659545                                 
# DMNR 0.57684427 0.01769236                      
# DILG 0.49380400 0.06424445 0.08157452           
# CFMG 0.43154385 0.09295712 0.09332092 0.02060062
####### Example: Output################################################
#     row  col      value
# 1  INTG CONT 0.56659545
# 2  DMNR CONT 0.57684427
# 3  DILG CONT 0.49380400
# 4  CFMG CONT 0.43154385
# 5  DMNR INTG 0.01769236
# 6  DILG INTG 0.06424445
# 7  CFMG INTG 0.09295712
# 8  DILG DMNR 0.08157452
# 9  CFMG DMNR 0.09332092
# 10 CFMG DILG 0.02060062
#=== Mathematical Representation of Widely used Wave Feature Extraction ####
WZY.EMG.F <- function(wzy, lastCol = FALSE) {
  library("biwavelet")
  require("biwavelet")
  if (lastCol) {
    wzy <- wzy[, -ncol(wzy)]
  }
  if (class(wzy) != "matrix") {
    wzy <- as.matrix(wzy)
  }
  #### Global Variabels ####
  wzyo<-wzy
  wzy<-wzy[,-1]
  ncol <- ncol(wzy)
  nrow <- nrow(wzy)
  ncolo <- ncol(wzyo)
  nrowo <- nrow(wzyo)
  #### Easy calculation features ####
  iemg <- colSums(abs(wzy)) # Integrated EMG (IEMG)
  mav <- iemg/nrow # Mean Absolute Value (MAV)
  var <- colSums(wzy^2)/(nrow-1) # Variance of EMG (VAR)
  rms <- sqrt(colSums(wzy^2)/nrow) # Root Mean Square (RMS)
  # Finished easy part
  ###
  #### calculate the maximum amplitude (MA) ####
  main<-0
  ma<-c()
  for (main in 1:ncol){
    ma<-c(ma, max(wzy[, main])-min(wzy[, main]))
  }
  # finished calculation of Maximum Amplitude (MA)
  ###
  #### calculate the Waveform Length (WL) ####
  wl <- c(0)
  absDiff <-0
  y<-0
  for(j in 1:ncol) {
    y <- 0
    for(i in 1:(nrow-1)) {
      absDiff <- abs(wzy[i+1,j]-wzy[i,j])
      y <- y + absDiff
    }
    wl[j]<-y
  }
  # Finished calculation of Waveform Length (WL)
  ###
  #### calculate the Main Period (MP) ####
  dw<-0
  mp<-c()
  for(dw in 2:ncolo){
    x<-c()
    y<-c()
    s<-c()
    max<-0
    row<-0
    dwt<-wt(cbind(wzyo[, 1], wzyo[, dw]))
    y<-rowSums(abs(dwt$wave)^2)
    x<-dwt$period
    s<-cbind(x, y)
    max<-max(y)
    row<-which(s[, 2] == max)
    out <- s[row, 1]
    mp<-c(mp, out)
  }
  mp<-as.vector(mp)
  # Finished calculation of Main Period (MP)
  ###
  #### calculate the Mean Power Frequency (MPF) ####
  timeStep <- wzyo[3, 1]-wzyo[2, 1]
  sampleSize <- nrow
  Fs <- sampleSize/(sampleSize*timeStep)
  N <- sampleSize
  seq <- c(1:(N/2))
  xv <-(seq/N)*Fs
  mpfin <- 0
  mpf<-c()
  for (mpfin in 1:ncol){
    X.k <- fft(wzy[, mpfin])
    mod <- Mod(X.k)
    mod<-mod[1:(N/2)]
    mpf <- c(mpf, sum(mod*xv)/sum(mod))
  }
  #= finished calculation of Mean Power Frequency
  ###
  ##### result construction ####
  res<-data.frame(
    row.names = colnames(wzy),
    Int = iemg,
    MAV = mav,
    VAR = var,
    RMS = rms,
    WL = wl,
    MP = mp,
    MA = ma,
    MPF = mpf
  )
  return(list(data=wzyo, results=res))
}

#=== Wavelet Analysis ####
WZY.Wavelet.clust <- function(input){ # wave clust in a same sample
  library("biwavelet")
  library("stringr")
  require("stringr")
  require("biwavelet")
  ncol<-NCOL(input)
  wt.t1 <- wt(cbind(input[ , 1], input[ , 2]))
  w.arr <- array(NA, dim = c(ncol-1, NROW(wt.t1$wave), NCOL(wt.t1$wave)))
  for(i in 2:ncol) {
    wt.t<-wt(cbind(input[ , 1], input[ , i]))
    w.arr[i-1, , ] <- wt.t$wave
  }
  w.arr.dis<-wclust(w.arr)
  w.arr.dis<-w.arr.dis$dist.mat
  w.arr.dis<-as.matrix(w.arr.dis)
  label <- colnames(input[, 2:ncol])
  label[1] <- str_c("====>", label[1])
  colnames(w.arr.dis)<-label
  row.names(w.arr.dis)<-label
  w.arr.dis<-as.dist(w.arr.dis)
  return(w.arr.dis)
}
#=== Frequency Spectrum ===####
# From: (http://www.di.fc.ul.pt/~jpn/r/fourier/fourier.html)
wzy.plot.frequency.spectrum <- function(X.k, sampleSize, timeStep) {
  X.k[1]<-0
  Fs<-sampleSize/(sampleSize*timeStep)
  N<-sampleSize
  seq<-c(1:(N/2))
  xv=(seq/N)*Fs
  mod<-Mod(X.k)
  mod<-mod[1:(N/2)]
  plot.data  <- cbind(c(0, xv[1:((N/2)-1)]), mod)
  plot.data[xv[2:(N/2)],2] <- 2*plot.data[xv[2:(N/2)],2] 
  plot(plot.data, t="h", lwd=2, main="", 
       xlab="Frequency (Hz)", ylab="Strength",
        ylim=c(0,max(Mod(plot.data[,2]))))+title(main = "Power Spectrum")
}

#=== Function for Batching Processing ===####
wzy.batch <- function (wzy) {
  library("biwavelet")
  require("biwavelet")
  if (lastCol) {
    wzy <- wzy[, -ncol(wzy)]
  }
  if (class(wzy) != "matrix") {
    wzy <- as.matrix(wzy)
  }
  #### Global Variabels ####
  wzyo<-wzy
  wzy<-wzy[,-1]
  ncol <- ncol(wzy)
  nrow <- nrow(wzy)
  ncolo <- ncol(wzyo)
  nrowo <- nrow(wzyo)
  #### Easy calculation features ####
  iemg <- colSums(abs(wzy)) # Integrated EMG (IEMG)
  mav <- iemg/nrow # Mean Absolute Value (MAV)
  var <- colSums(wzy^2)/(nrow-1) # Variance of EMG (VAR)
  rms <- sqrt(colSums(wzy^2)/nrow) # Root Mean Square (RMS)
  # Finished easy part
  ###
  #### calculate the maximum amplitude (MA) ####
  main<-0
  ma<-c()
  for (main in 1:ncol){
    ma<-c(ma, max(wzy[, main])-min(wzy[, main]))
  }
  # finished calculation of Maximum Amplitude (MA)
  ###
  #### calculate the Waveform Length (WL) ####
  wl <- c(0)
  absDiff <-0
  y<-0
  for(j in 1:ncol) {
    y <- 0
    for(i in 1:(nrow-1)) {
      absDiff <- abs(wzy[i+1,j]-wzy[i,j])
      y <- y + absDiff
    }
    wl[j]<-y
  }
  # Finished calculation of Waveform Length (WL)
  ###
  #### calculate the Main Period (MP) ####
  dw<-0
  mp<-c()
  for(dw in 2:ncolo){
    x<-c()
    y<-c()
    s<-c()
    max<-0
    row<-0
    dwt<-wt(cbind(wzyo[, 1], wzyo[, dw]))
    y<-rowSums(abs(dwt$wave)^2)
    x<-dwt$period
    s<-cbind(x, y)
    max<-max(y)
    row<-which(s[, 2] == max)
    out <- s[row, 1]
    mp<-c(mp, out)
  }
  mp<-as.vector(mp)
  # Finished calculation of Main Period (MP)
  ###
  #### calculate the Mean Power Frequency (MPF) ####
  timeStep <- wzyo[3, 1]-wzyo[2, 1]
  sampleSize <- nrow
  Fs <- sampleSize/(sampleSize*timeStep)
  N <- sampleSize
  seq <- c(1:(N/2))
  xv <-(seq/N)*Fs
  mpfin <- 0
  mpf<-c()
  for (mpfin in 1:ncol){
    X.k <- fft(wzy[, mpfin])
    mod <- Mod(X.k)
    mod<-mod[1:(N/2)]
    mpf <- c(mpf, sum(mod*xv)/sum(mod))
  }
  #= finished calculation of Mean Power Frequency
  ###
  ##### result construction ####
  res<-data.frame(
    row.names = colnames(wzy),
    Int = iemg,
    MAV = mav,
    VAR = var,
    RMS = rms,
    WL = wl,
    MP = mp,
    MA = ma,
    MPF = mpf
  )
  return(list(data=wzyo, results=res))
}