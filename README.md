
<!-- README.md is generated from README.Rmd. Please edit that file -->

# The {ra} R package<img src="man/figures/logo.png" align="right" width="25%"/><br><small><font color="#999">A minimal TileDB-backed lazy multi-dimensional array implementation with metadata</font></small>

<!-- badges: start -->

[![GitHub R package
version](https://img.shields.io/github/r-package/v/rogiersbart/ra?label=version)](https://github.com/rogiersbart/ra)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/ra.svg)](https://CRAN.R-project.org/package=ra)
<!-- badges: end -->

The {ra} R package provides a wrapper around the low-level
{[tiledb](https://tiledb-inc.github.io/TileDB-R/)} API and
{[jsonlite](https://jeroen.r-universe.dev/jsonlite)}, to implement a
minimal lazy multi-dimensional array with arbitrary metadata support.

The motivation for {ra} comes from the fact that the high-level {tiledb}
API (square bracket subsetting and subassignment) for dense arrays is
limited only to [2D for subarray
writes](https://github.com/TileDB-Inc/TileDB-R/blob/47b3185f3f696072060c0255a3b1605e9fb33a16/R/TileDBArray.R#L1469),
and [3D for subarray
reads](https://github.com/TileDB-Inc/TileDB-R/blob/47b3185f3f696072060c0255a3b1605e9fb33a16/R/TileDBArray.R#L532).
Additionally, metadata support is limited to strings, while we can get
arbitrarily complex metadata through the use of JSON.

# Install

You can install the latest version of {ra} from GitHub with the
following:

``` r
if (!require(pak)) install.packages("pak")
pak::pak("rogiersbart/ra")
```

# Use

``` r
ra <- ra::ra(5, 4, 2)
dim(ra)
#> [1] 5 4 2

# read
ra[1:5,1:2,1:2]
#> , , 1
#> 
#>      [,1] [,2]
#> [1,]  255  255
#> [2,]  255  255
#> [3,]  255  255
#> [4,]  255  255
#> [5,]  255  255
#> 
#> , , 2
#> 
#>      [,1] [,2]
#> [1,]  255  255
#> [2,]  255  255
#> [3,]  255  255
#> [4,]  255  255
#> [5,]  255  255
ra[1,,]
#>      [,1] [,2]
#> [1,]  255  255
#> [2,]  255  255
#> [3,]  255  255
#> [4,]  255  255
ra[1]
#>      [,1] [,2]
#> [1,]  255  255
#> [2,]  255  255
#> [3,]  255  255
#> [4,]  255  255
ra[1, , 1]
#> [1] 255 255 255 255
ra[]
#> , , 1
#> 
#>      [,1] [,2] [,3] [,4]
#> [1,]  255  255  255  255
#> [2,]  255  255  255  255
#> [3,]  255  255  255  255
#> [4,]  255  255  255  255
#> [5,]  255  255  255  255
#> 
#> , , 2
#> 
#>      [,1] [,2] [,3] [,4]
#> [1,]  255  255  255  255
#> [2,]  255  255  255  255
#> [3,]  255  255  255  255
#> [4,]  255  255  255  255
#> [5,]  255  255  255  255

# write
ra[1,1,1] <- 0L
ra[3,1:4,2] <- rep(1, 4)
ra[,4, 2] <- rep(3, 5)
ra[]
#> , , 1
#> 
#>      [,1] [,2] [,3] [,4]
#> [1,]    0  255  255  255
#> [2,]  255  255  255  255
#> [3,]  255  255  255  255
#> [4,]  255  255  255  255
#> [5,]  255  255  255  255
#> 
#> , , 2
#> 
#>      [,1] [,2] [,3] [,4]
#> [1,]  255  255  255    3
#> [2,]  255  255  255    3
#> [3,]    1    1    1    3
#> [4,]  255  255  255    3
#> [5,]  255  255  255    3

# squash
fs::dir_info(ra$path, recurse = TRUE)$size |> sum()
#> 14.6K
ra::squash(ra)
fs::dir_info(ra$path, recurse = TRUE)$size |> sum()
#> 5K

# metadata
ra::metadata(ra)
#> NULL
ra::metadata(ra) <- list(name = "Demo {ra} array", purpose = "Demonstrate use")
ra::metadata(ra)
#> $name
#> [1] "Demo {ra} array"
#> 
#> $purpose
#> [1] "Demonstrate use"
```

# Note

Both {[lazyarray](https://cran.r-project.org/package=lazyarray)} and its
successor {[filearray](https://cran.r-project.org/package=filearray)}
provide similar functionality.
