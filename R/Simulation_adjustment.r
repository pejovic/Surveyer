
# Packages
library(tidyverse)
library(magrittr)
library(ggplot2)
library(geomnet)
library(ggnetwork)
library(sf)
library(ggmap)
library(sp)
library(rgdal)
library(leaflet)
library(xlsx)
library(data.table)
library(mapview)
library(mapedit)
library(leaflet.extras)
library(here)
library(matlib)
library(nngeo)
library(writexl)
library(here)


source("./R/functions.r")
source("./R/Simulations_functions.r")


A <- c(393.979,	419.038)
B <- c(366.358, 550.138)
C <- c(601.903, 632.171)
D <- c(705.481, 538.638)
O1 <- c(500.000, 500.000)
O2 <- c(585.023, 548.609)

points <- rbind(A, B, C, D, O1, O2) %>% as.data.frame() %>% rownames_to_column("Name") %>% rename(x = V1, y = V2)
points <- points %>% dplyr::mutate(id = row_number(), FIX_X = FALSE, FIX_Y = FALSE, Point_object = FALSE) %>% dplyr::select(id, Name, x, y, FIX_X, FIX_Y, Point_object)


obs_plan <- data.frame(station = rep(c("A", "A", "A", "B", "B", "B", "C", "C", "C", "D", "D", "D"), 2),
                       obs.point = rep(c("B", "O1", "O2", "A", "O2", "O1", "D", "O2","O1", "C", "O1", "O2"), 2),
                       type = c(rep("p", 12), rep("d", 12)), stringsAsFactors = FALSE)
obs_plan <- obs_plan[-which(obs_plan$obs.point %in% c("A", "B", "C", "D") & obs_plan$type == "d"), ]


sim.obs <- function(points, obs.plan, Hz0 = NA, red = TRUE, sd_Hz = 10, sd_dist = 3, sd_cent_station = 2, sd_cent_target = 3, seed = NULL){
  obs.dist <- filter(obs.plan, type == "d") %>% select(1,2) # Selekcija merenih duzina
  sim.dist <- sim_dist_all(obs_d = obs.dist, points = points, sd_cent_station = sd_cent_station, sd_cent_target = sd_cent_target, seed = seed)

  obs.Hz <- filter(obs.plan, type == "p") %>% select(1,2) # Selekcija merenih pravaca
  sim.Hz <- sim_Hz_all(obs_Hz = obs.Hz, points = points, Hz0 = Hz0, red = red, sd_cent_station = sd_cent_station, sd_cent_target = sd_cent_target, sd_Hz = sd_Hz, seed = seed)

  obs <- dplyr::full_join(sim.Hz, sim.dist) %>%
    mutate(sd_Hz = sd_Hz, sd_dist = sd_dist, SD = NA, VzD = NA, VzM = NA, VzS = NA, sd_Vz = NA) %>%
    dplyr::select(from = station, to = obs.point, HzD = deg, HzM = minut, HzS = sec, HD = dist, SD, VzD, VzM, VzS, sd_Hz, sd_dist, sd_Vz)
  obs.list <- list(Points = points, Observations = obs)
  return(obs.list)
}

sim.survey.net.raw <- sim.obs(points = points, obs.plan = obs_plan)

sim.survey.net <- import_surveynet2D(points = sim.survey.net.raw[[1]], observations = sim.survey.net.raw[[2]])

A <- Amat(survey.net = sim.survey.net, units = "mm")
f <- data.frame(f = fmat(survey.net = sim.survey.net))
P <- data.frame(Wmat(survey.net = sim.survey.net, apriori = 5))

design.snet(survey.net = sim.survey.net, apriori = 1, prob = NA, result.units = list("mm", "cm", "m"), ellipse.scale = 1, axes = c("Easting", "Northing"), teta.unit = list("deg", "rad"), all = FALSE)

survey.net = sim.survey.net; apriori = 1; prob = NA; result.units = list("mm", "cm", "m"); ellipse.scale = 1; axes = c("Easting", "Northing"); teta.unit = list("deg", "rad"); all = FALSE

writexl::write_xlsx(obs1_list, path = "obs11_list.xlsx")

# Zadatak

z_points <- readxl::read_xlsx(path = here::here("Data/Input/Without_observations/xlsx/zadatak_1462019.xlsx"), sheet = "Points", col_types = c("numeric", "text", "numeric", "numeric", "logical", "logical", "logical"))
z_obs <- readxl::read_xlsx(path = here::here("Data/Input/Without_observations/xlsx/zadatak_1462019.xlsx"), sheet = "Observations", col_types = c("text", "text", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric", "numeric","numeric","numeric", "numeric", "numeric"))
z.survey.net <- import_surveynet2D(points = z_points, observations = z_obs)

design.snet(survey.net = z.survey.net, apriori = 1, prob = NA, result.units = list("mm", "cm", "m"), ellipse.scale = 1, axes = c("Easting", "Northing"), teta.unit = list("deg", "rad"), all = FALSE)



