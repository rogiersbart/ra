#' Title
#'
#' @param path
#' @param type
#' @param dim
#' @param dimnames
#'
#' @return
#' @export
#'
#' @examples
ra <- function(..., path = tempfile(), type = "UINT8", filter = "NONE", tiles = 1) {
  # TODO
  # - allow filter combinations?
  # - consider making path first argument again? as in practice, this is always used?
  if (length(list(...)) != 0) {
    if (file.exists(path)) unlink(path, recursive = TRUE)
    if ("array" %in% class(list(...)[[1]])) {
      input <- list(...)[[1]]
      ra_object <- ra(dim(input), path = path, type = type, filter = filter, tiles = tiles)
      ra_object[] <- input
      return(ra_object)
    }
  }
  dim <- c(...)
  if (!file.exists(path)) {
    dim <- as.integer(dim)
    if (length(tiles) == 1) tiles <- rep(tiles, length(dim))
    dimnames <- dim_names(length(dim))
    dom <- tiledb::tiledb_domain(dims = lapply(
      1:length(dim),
      \(x) tiledb::tiledb_dim(dimnames[x], c(1L, dim[x]), as.integer(ceiling(dim[x] / tiles[x])), "INT32")
    ))
    schema <- tiledb::tiledb_array_schema(
      dom,
      attrs=tiledb::tiledb_attr(
        "values",
        type = type,
        filter_list = tiledb::tiledb_filter_list(
          tiledb::tiledb_filter(filter)
        )
      )
    )
    tiledb::tiledb_array_create(path, schema)
  }
  ra_object <- list(path = path)
  class(ra_object) <- c("ra_object", "array")
  ra_object
}
dim_names <- function(n) {
  paste0("dim_", 1:n)
}

#' @export
`[.ra_object` <- function(x, i, j, ...) {
  tdb_read(x$path, tiledb:::nd_index_from_syscall(sys.call(), parent.frame()))
}
tdb_read <- function(uri, indices) {
  tdb <- tiledb::tiledb_array(uri, is.sparse = FALSE, return_as = "array")
  tiledb::selected_ranges(tdb) <- get_selected_ranges(tdb, indices)
  drop(tdb[][[1]])
}

#' @export
`[<-.ra_object` <- function(x, i, j, ..., value) {
  tdb_write(
    x$path,
    tiledb:::nd_index_from_syscall(sys.call(), parent.frame()),
    data = value
  )
  x
}
get_selected_ranges <- function(tdb, indices) {
  dimensions <- tiledb::schema(tdb) |> tiledb::dimensions()
  if (length(indices) == 0) {
    indices <- lapply(dimensions, tiledb::domain)
  } else if (any(unlist(lapply(indices, is.null)))) {
    for (i in 1:length(dimensions)) {
      if (i > length(indices)) {
        indices[[i]] <- tiledb::domain(dimensions[[i]])
      } else if (is.null(indices[[i]])) {
        indices[[i]] <- tiledb::domain(dimensions[[i]])
      }
    }
  }
  indices_min <- lapply(indices, min) |> unlist()
  indices_max <- lapply(indices, max) |> unlist()
  ndims <- length(indices)
  ranges <- cbind(indices_min, indices_max) |> unname()
  selected_ranges <- lapply(1:ndims, \(x) ranges[x, , drop = FALSE])
  names(selected_ranges) <- dim_names(ndims)
  selected_ranges
}
tdb_write <- function(uri, indices, data) {
  tdb <- tiledb::tiledb_array(uri, is.sparse = FALSE, return_as = "array")
  schema <- tiledb::schema(tdb)
  query <- tdb |>
    tiledb::tiledb_query("WRITE")
  selected_ranges <- get_selected_ranges(tdb, indices)

  n <- prod(1 + lapply(selected_ranges, \(x) diff(t(x))) |> unlist())
  if (length(data) == 1) data <- rep(data, n)

  buffer <- tiledb::tiledb_query_create_buffer_ptr(query, tiledb::datatype(tiledb::attrs(schema)[[1]]), data)
  query <- query |>
    tiledb::tiledb_query_set_buffer_ptr("values", buffer) |>
    # tiledb::tiledb_query_set_buffer("values", data) |>
    tiledb::tiledb_query_set_layout("COL_MAJOR")
  tdb_dim_names <- dim_names(length(selected_ranges))
  subarr <- as.integer(unlist(selected_ranges, use.names = FALSE))
  query |>
    tiledb::tiledb_query_set_subarray(subarr, "INT32") |>
    tiledb::tiledb_query_submit() |>
    tiledb::tiledb_query_finalize()
  invisible()
}

#' @export
print.ra_object <- function(x) {
  std::err("# {.pkg ra} lazy array")
  # TODO change to $ when {std} is updated
  std::err("i path: {.path {x$path |> normalizePath(winslash = \"/\")}}")
  # std::err("i class: {.val {class(x)[1]}}")
  # std::err("i type: {.val {typeof(x)}}")
}

#' @export
dim.ra_object <- function(x) {
  tdb <- tiledb::tiledb_array(x$path)
  schema <- tiledb::schema(tdb)
  dim(schema)
}

#' @export
summary.ra_object <- function(x) {
  tdb <- tiledb::tiledb_array(x$path)
  schema <- tiledb::schema(tdb)
  dims <- schema |> tiledb::dimensions()
  std::err("# {.pkg ra} lazy array")
  std::err("i path: {.path {x$path |> normalizePath(winslash = \"/\")}}")
  # std::err("i class: {.val {class(x)[1]}}")
  # std::err("i type: {.val {typeof(x)}}")
  std::err("i dim: {.val {dim(x) |> paste0(collapse = 'x')}}")
  std::err("i type: {.val {tiledb::attrs(schema)[[1]] |> tiledb::datatype()}}")
  # std::err("i dimnames: {.val {lapply(dims, tiledb::name) |> unlist()}}")
  std::err("i metadata: {.val {!is.null(metadata(x))}}")
}
