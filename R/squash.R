#' Title
#'
#' @param ra_object
#'
#' @return
#' @export
#'
#' @examples
squash <- function(ra_object) {
  tiledb::array_consolidate(ra_object$path)
  tiledb::array_vacuum(ra_object$path)
}
