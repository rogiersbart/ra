#' Title
#'
#' @param ra_object
#'
#' @return
#' @export
#'
#' @examples
metadata <- function(ra_object) {
  db <- tiledb::tiledb_array(ra_object$path)
  db <- tiledb::tiledb_array_open(db, "READ")
  metadata <- db |> tiledb::tiledb_has_metadata("metadata")
  if (!metadata) return(NULL)
  value <- db |> tiledb::tiledb_get_metadata("metadata")
  db <- tiledb::tiledb_array_close(db)
  jsonlite::fromJSON(value)
}
#' @export
`metadata<-` <- function(ra_object, value) {
  db <- tiledb::tiledb_array(ra_object$path)
  db <- tiledb::tiledb_array_open(db, "WRITE")
  tiledb::tiledb_put_metadata(db, "metadata", jsonlite::toJSON(value))
  db <- tiledb::tiledb_array_close(db)
  ra_object
}
