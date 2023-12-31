% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/functions.R
\name{distTApply}
\alias{distTApply}
\title{Computes the distributed R tapply function}
\usage{
distTApply(X, INDEX, ...)
}
\arguments{
\item{X}{an array, including a matrix.}

\item{INDEX}{factor of the same length as X.}

\item{...}{Arguments of \link[base]{tapply}}
}
\value{
token for the operation
}
\description{
This function works the same way as \link[base]{tapply}
Returns an unique token for the operation, for more information
on getting the results of the operation, see \link{getResults}.
}
