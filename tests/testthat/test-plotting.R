context("Plotting data")

polygons <- list()
n_polygon_per_side <- 10
n_polygons <- n_polygon_per_side * n_polygon_per_side
n_pixels_per_side <- n_polygon_per_side * 2

for(i in 1:n_polygons) {
  row <- ceiling(i/n_polygon_per_side)
  col <- ifelse(i %% n_polygon_per_side != 0, i %% n_polygon_per_side, n_polygon_per_side)
  xmin = 2*(col - 1); xmax = 2*col; ymin = 2*(row - 1); ymax = 2*row
  polygons[[i]] <- rbind(c(xmin, ymax), c(xmax,ymax), c(xmax, ymin), c(xmin,ymin))
}

polys <- do.call(raster::spPolygons, polygons)
response_df <- data.frame(area_id = 1:n_polygons, response = runif(n_polygons, min = 0, max = 1000))
response_df2 <- data.frame(area_id = 1:n_polygons, n_positive = runif(n_polygons, min = 0, max = 1), sample_size = floor(runif(n_polygons, min = 1, max = 100)))
spdf <- sp::SpatialPolygonsDataFrame(polys, response_df)
spdf2 <- sp::SpatialPolygonsDataFrame(polys, response_df2)

# Create raster stack
r <- raster::raster(ncol=n_pixels_per_side, nrow=n_pixels_per_side)
r <- raster::setExtent(r, raster::extent(spdf))
r[] <- sapply(1:raster::ncell(r), function(x) rnorm(1, ifelse(x %% n_pixels_per_side != 0, x %% n_pixels_per_side, n_pixels_per_side), 3))
r2 <- raster::raster(ncol=n_pixels_per_side, nrow=n_pixels_per_side)
r2 <- raster::setExtent(r2, raster::extent(spdf))
r2[] <- sapply(1:raster::ncell(r), function(x) rnorm(1, ceiling(x/n_pixels_per_side), 3))
cov_stack <- raster::stack(r, r2)

if(identical(Sys.getenv("NOT_CRAN"), "true")) {
  test_data <- prepare_data(polygon_shapefile = spdf, 
                            covariate_rasters = cov_stack)
} else {
  test_data <- prepare_data(polygon_shapefile = spdf, 
                            covariate_rasters = cov_stack,
                            makeMesh = FALSE)
}

test_that("Check plot_polygon_data function works as expected", {
  
  skip_on_cran()
  
  p <- plot_polygon_data(spdf, list(id_var = 'area_id', response_var = 'response'))
  expect_error(plot_polygon_data(polys, list(id_var = 'area_id', response_var = 'response')))
  expect_is(p, 'ggplot')
  
  p2 <- plot_polygon_data(spdf2, list(id_var = 'area_id', response_var = 'n_positive'))
  expect_is(p2, 'ggplot')
  
})

test_that("Check plot.disag.data function works as expected", {
  
  skip_on_cran()
  
  test_data2 <- prepare_data(polygon_shapefile = spdf2, 
                             covariate_rasters = cov_stack,
                             response_var = 'n_positive')
  
  p <- plot(test_data)
  
  expect_is(p, 'list')
  expect_equal(length(p), 2)
  expect_equal(names(p), c('polygon', 'covariates'))
  
  p2 <- plot(test_data2)
  
  expect_is(p2, 'list')
  expect_equal(length(p2), 2)
  expect_equal(names(p2), c('polygon', 'covariates'))
  
})

test_that("Check plot.fit.result function works as expected", {
  
  skip_if_not_installed('INLA')
  skip_on_cran()
  
  fit_result <- fit_model(test_data, iterations = 2)
  
  fit_result_nofield <- fit_model(test_data, iterations = 2, field = FALSE)
  
  p1 <- plot(fit_result)
  
  p2 <- plot(fit_result_nofield)
  
  expect_is(p1, 'list')
  expect_equal(length(p1), 2)
  
  expect_is(p2, 'list')
  expect_equal(length(p2), 2)
  
  
})

test_that("Check plot.predictions function works as expected", {
  
  skip_if_not_installed('INLA')
  skip_on_cran()
  
  fit_result <- fit_model(test_data, iterations = 2)
  
  fit_result_nofield <- fit_model(test_data, iterations = 2, field = FALSE)
  
  preds <- predict_model(fit_result)
  p1 <- plot(preds)
  
  preds_nofield <- predict_model(fit_result_nofield)
  p2 <- plot(preds_nofield)
  
  preds_withiid <- predict_model(fit_result, predict_iid = TRUE)
  p3 <- plot(preds_withiid)
  
  unc <- predict_uncertainty(fit_result)
  p4 <- plot(unc)
  
  expect_is(p1, 'list')
  expect_equal(length(p1), 3)
  expect_is(p1[[1]], 'trellis')
  expect_is(p1[[2]], 'trellis')
  expect_is(p1[[3]], 'trellis')
  
  expect_is(p2, 'list')
  expect_equal(length(p2), 2)
  expect_is(p2[[1]], 'trellis')
  expect_is(p2[[2]], 'trellis')
  
  expect_is(p3, 'list')
  expect_equal(length(p3), 4)
  expect_is(p3[[1]], 'trellis')
  expect_is(p3[[2]], 'trellis')
  expect_is(p3[[3]], 'trellis')
  expect_is(p3[[4]], 'trellis')
  
  expect_is(p4, 'trellis')
  
})

