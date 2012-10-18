# Installing R

This documentation lists how to install R, rmr, and rhdfs on an HDP 1.1 deployment.  Before you begin, please make sure you have downloaded R (if you plan to build it from source vs RPM), rmr, and rhdfs from the [RHadoop GitHub Repo](https://github.com/RevolutionAnalytics/RHadoop/wiki/Downloads).  For convenience you can use the scripts in this repo to automate the installation process.

## Mandatory Environmental Variables

	cat > /etc/profile.d/r.sh <<END
	. /usr/lib/hadoop/bin/hadoop-config.sh --config /etc/hadoop/conf
	export HADOOP_CMD=/usr/bin/hadoop
	export HADOOP_STREAMING=/usr/lib/hadoop/contrib/streaming/hadoop-streaming-1.0.3.15.jar
	END

## Installation Options

### RPM Install

	# yum install R

### Source Install

#### Dependencies

	# yum groupinstall "Development Tools"
	# yum install readline-devel

#### Installation

	# cd R-*
	# ./configure --with-x=no
	
	... truncated ...
	
	R is now configured for x86_64-unknown-linux-gnu

	  Source directory:          .
	  Installation directory:    /usr/local

	  C compiler:                gcc -std=gnu99  -g -O2
	  Fortran 77 compiler:       gfortran  -g -O2

	  C++ compiler:              g++  -g -O2
	  Fortran 90/95 compiler:    gfortran -g -O2
	  Obj-C compiler:	      

	  Interfaces supported:      
	  External libraries:        readline
	  Additional capabilities:   NLS
	  Options enabled:           shared BLAS, R profiling, Java

	  Recommended packages:      yes

	configure: WARNING: you cannot build info or HTML versions of the R manuals
	configure: WARNING: you cannot build PDF versions of the R manuals
	configure: WARNING: you cannot build PDF versions of vignettes and help pages
	# make
	# make check
	# make install
	
## R Validation

	# R

	R version 2.15.1 (2012-06-22) -- "Roasted Marshmallows"
	Copyright (C) 2012 The R Foundation for Statistical Computing
	ISBN 3-900051-07-0
	Platform: x86_64-unknown-linux-gnu (64-bit)

	R is free software and comes with ABSOLUTELY NO WARRANTY.
	You are welcome to redistribute it under certain conditions.
	Type 'license()' or 'licence()' for distribution details.

	  Natural language support but running in an English locale

	R is a collaborative project with many contributors.
	Type 'contributors()' for more information and
	'citation()' on how to cite R or R packages in publications.

	Type 'demo()' for some demos, 'help()' for on-line help, or
	'help.start()' for an HTML browser interface to help.
	Type 'q()' to quit R.

	> q()
	Save workspace image? [y/n/c]: n
	
## Install R projects

	# echo 'options(repos=structure(c(CRAN="http://cran.stat.ucla.edu")))' >> /root/.Rprofile
	# Rscript -e 'install.packages("RJSONIO");'
	# Rscript -e 'install.packages("itertools");'
	# Rscript -e 'install.packages("digest");'
	# Rscript -e 'install.packages("Rcpp");'
	# R CMD INSTALL rmr /path/to/rmr_1.3.1.tar.gz
	# R CMD javareconf
	# Rscript -e 'install.packages("rJava");'
	# R CMD INSTALL rhdfs /path/to/rhdfs_1.0.5.tar.gz
	
# RHadoop Validation
Execute these commands from R

	groups = rbinom(100, n = 500, prob = 0.5)
	tapply(groups, groups, length)
	require('rmr')
	groups = rbinom(100, n = 500, prob = 0.5)
	groups = to.dfs(groups)
	result = mapreduce(
	    input = groups,
	    map = function(k,v) keyval(v, 1),
	    reduce = function(k,vv) keyval(k, length(vv)))
	print(result())
	print(from.dfs(result, to.data.frame=T))
	
# Installing RStudio Server (Optional)

	# yum install openssl098e
	# yum install compat-libgfortran-41
	# wget http://download2.rstudio.org/rstudio-server-0.96.331-x86_64.rpm
	# rpm -ivh rstudio-server-0.96.331-x86_64.rpm

Now refer to the [R-Studio Getting Started guide](http://rstudio.org/docs/server/getting_started)