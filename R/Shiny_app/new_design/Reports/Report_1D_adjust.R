#' ---
#' title: "Report - 1D geodetic network adjustment"
#' author:
#'    - "surveyor - R package"
#' date: "`r format(Sys.time(), '%d %B %Y')`"
#' output:
#'    html_document:
#'      keep_md: true
#'      theme: "simplex"
#'      highlight: tango
#'      toc: true
#'      toc_depth: 5
#'      toc_float: true
#'      fig_caption: yes
#'
#' params:
#'   model: NA,
#'   data: NA,
#'   data_up: NA,
#'   net1d_adj: NA,
#'   sd_h_bound: NA,
#'   rii_bound: NA
#'   sd.apriori: NA
#'   sd.estimated: NA
#'   df: NA
#'   iter: NA
#' ---
#'
#'<img src="Grb_Gradjevinski.png" align="center" alt="logo" width="180" height = "220" style = "border: none; fixed: right;">
#'
#'
#+ include = TRUE, echo = FALSE, results = 'hide', warning = FALSE, message = FALSE
source(here::here("R/functions.r"))

#+ include = TRUE, echo = FALSE, results = 'hide', warning = FALSE, message = FALSE
library(shiny)
library(shinythemes)
library(leaflet)
library(tidyverse)
library(magrittr)
library(ggplot2)
library(sf)
library(ggmap)
library(sp)
library(rgdal)
library(leaflet)
library(readxl)
library(data.table)
library(plotly)
library(mapview)
library(shinycssloaders)
library(here)
library(matlib)
library(nngeo)
library(dplyr)
library(mapedit)
library(DT)
library(leaflet.extras)
library(rhandsontable)
library(shinyBS)
library(shinyWidgets)
library(knitr)
library(rmarkdown)
library(knitr)
library(kableExtra)



#'
#'
#+ include = FALSE
# Plot settings
my_theme <- function(base_size = 10, base_family = "sans"){
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      axis.text = element_text(size = 10),
      axis.text.x = element_text(angle = 0, vjust = 0.5, hjust = 0.5),
      axis.title = element_text(size = 12),
      panel.grid.major = element_line(color = "grey"),
      panel.grid.minor = element_blank(),
      panel.background = element_rect(fill = "#fffcfc"),
      strip.background = element_rect(fill = "#820000", color = "#820000", size =0.5),
      strip.text = element_text(face = "bold", size = 10, color = "white"),
      legend.position = "bottom",
      legend.justification = "center",
      legend.background = element_blank(),
      panel.border = element_rect(color = "grey30", fill = NA, size = 0.5)
    )
}

theme_set(my_theme())
mycolors=c("#f32440","#2185ef","#d421ef")
#+ echo = FALSE, message = FALSE, warning = FALSE
#' This report provides the main results regarding the design of 1D geodetic network.
#'
#' # Summary
#+ echo = FALSE, message = FALSE, warning = FALSE

if(length(params$data_up) == 0){
  data = params$data
}else{
  data = params$data_up
}

modeltest <- model_adequacy_test.shiny(sd.apriori = params$sd.apriori, sd.estimated = params$sd.estimated, df = params$df, prob = 0.95)


summary.adjustment <- data.frame(Parameter = c("Type: ", "Dimension: ", "Number of iterations: ", "Max. coordinate correction in last iteration: ", "Datum definition: ", "Stochastic model: ", "Sd apriori: ", "Sd aposteriori: ", "Probability: ", "F estimated: ", "F quantile: ", "Model adequacy test: "),
                                 Value = c("Weighted", "1D", params$iter, "0.001 m",
                                           if(length(which(data$points$FIX_1D))==1 || length(which(data$points$FIX_1D))==0){
                                             "Free 1D geodetic network"
                                           }else{"Unfree 1D geodetic network"},
                                           params$model,
                                           params$sd.apriori,
                                           round(params$sd.estimated,5),
                                           0.95,
                                           round(modeltest$F.estimated, 5),
                                           round(modeltest$F.quantile, 5),
                                           modeltest$model

                                 ))

summary.adjustment %>%
  kable(caption = "Network adjustment", digits = 4, align = "c", col.names = NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), full_width = TRUE)%>%
  row_spec(12, bold = T, color = "white", background = "#D7261E")

summary.stations <- data.frame(Parameter = c("Number of (partly) known stations: ", "Number of unknown stations: ", "Total: "),
                               Value = c(sum(data$points$FIX_1D == TRUE),
                                         sum(data$points$FIX_1D == FALSE),
                                         sum(data$points$FIX_1D == TRUE) + sum(data$points$FIX_1D == FALSE)))

summary.stations %>%
  kable(caption = "Stations", digits = 4, align = "c", col.names = NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), full_width = TRUE)

summary.observations <- data.frame(Parameter = c("Leveled Height Differences: ", "Known coordinates: ", "Total: "),
                                   Value = c(sum(data$observations$diff_level == TRUE),
                                             sum(data$points$FIX_1D == TRUE)*1,
                                             sum(data$observations$diff_level == TRUE)+sum(data$points$FIX_1D == TRUE)*1))

summary.observations %>%
  kable(caption = "Observations", digits = 4, align = "c", col.names = NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), full_width = TRUE)

summary.unknowns <- data.frame(Parameter = c("Coordinates: ", "Total: "),
                               Value = c(sum(data$points$FIX_1D == FALSE)*1,
                                         sum(data$points$FIX_1D == FALSE)*1))

summary.unknowns %>%
  kable(caption = "Unknowns", digits = 4, align = "c", col.names = NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), full_width = TRUE)

summary.degrees <- data.frame(Parameter = "Degrees of freedom: ",
                              Value = (sum(data$observations$diff_level == TRUE)+sum(data$points$FIX_1D == TRUE))-sum(data$points$FIX_1D == FALSE))

summary.degrees %>%
  kable(caption = "Degrees of freedom: ", digits = 4, align = "c", col.names = NULL) %>%
  kable_styling(bootstrap_options = c("striped", "hover", "condensed", "responsive"), full_width = TRUE)


#'
#'
#'
#+ echo = FALSE, message = FALSE, warning = FALSE
adj.1dnet_map <- plot_surveynet(snet.adj = params$net1d_adj, webmap = FALSE, net.1D = TRUE, net.2D = FALSE)
#'
#' # Plot results
#+ echo = FALSE, result = TRUE, eval = TRUE, out.width="100%"
adj.1dnet_map

#'
#' # Tab results
#' ## Net points
#'
#+ echo = FALSE, result = TRUE, eval = TRUE, out.width="100%"
DT::datatable(
    params$net1d_adj[[1]] %>%
      as.data.frame() %>%
      mutate(
        h0 = round(h0, 2),
        dh = round(dh, 2),
        h = round(h, 2),
        sd_h = round(sd_h, 2)
      ) %>%
      dplyr:: select(Name, FIX_1D, Point_object, h0, h, dh, sd_h),
    escape=F,
    extensions = list('Buttons', 'Scroller'),
    options = list(dom = 'Bfrtip', buttons = I('colvis'), pageLength = 100,
                   deferRender = TRUE,
                   scrollY = 500,
                   scrollX = 300,
                   scroller = TRUE)
  ) %>%
    formatStyle(
      'sd_h',
      color = styleInterval(c(params$sd_h_bound), c('black', 'aqua')),
      backgroundColor = styleInterval(params$sd_h_bound, c('lightGray', '#FF6347'))
    )





#'
#' ## Observations
#'
#+ echo = FALSE, result = TRUE, eval = TRUE, out.width="100%"
DT::datatable(
    params$net1d_adj[[2]] %>%
      as.data.frame() %>%
      mutate(
        f = round(f, 2),
        Kl = round(Kl, 2),
        Kv = round(Kv, 2),
        rii = round(rii, 2)
      ) %>%
      dplyr::select(from, to, type, f, Kl, Kv, rii),
    escape=F,
    extensions = list('Buttons', 'Scroller'),
    options = list(dom = 'Bfrtip', buttons = I('colvis'), pageLength = 100,
                   deferRender = TRUE,
                   scrollY = 500,
                   scrollX = 300,
                   scroller = TRUE)
  )%>%
    formatStyle(
      'rii',
      color = styleInterval(c(params$rii_bound), c('red', 'black')),
      background = styleColorBar(params$net1d_adj[[2]]$rii, 'steelblue'),
      backgroundSize = '100% 90%',
      backgroundRepeat = 'no-repeat',
      backgroundPosition = 'center'
    )

