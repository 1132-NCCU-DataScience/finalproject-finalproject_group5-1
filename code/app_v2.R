# Load libraries
library(shiny)
library(bslib)
library(leaflet)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(ggcorrplot)
library(scales)
library(geosphere)

# === Load data ===

# Your existing data
data <- read.csv(xzfile("data/YouBike_availability_0424-0524.csv.xz")) |>
  mutate(
    Time = ymd_hms(SrcUpdateTime, tz = "Asia/Taipei"),
    Date = date(Time),
    Hour = hour(Time)
  )
station_list <- read.csv("data/station_base_info_s.csv") |>
  semi_join(data, by = c("StationUID" = "StationUID"))

data <- data |>
  group_by(UID = StationUID, Date, Hour) |>
  summarise(
    Bikes = mean(AvailableRentBikes),
    Spaces = mean(AvailableReturnBikes),
    Size = mean(AvailableRentBikes + AvailableReturnBikes),
    Value = mean(2 * (
      AvailableRentBikes / (AvailableRentBikes + AvailableReturnBikes)
    ) - 1),
    .groups = "drop"
  )

# Additional combined data
station_info <- read.csv("data/station_base_info.csv")
station_info2 <- read.csv("data/station_base_info_s.csv")
availability <- read.csv(xzfile("data/YouBike_availability_0424-0524.csv.xz")) %>%
  mutate(UpdateTime = ymd_hms(UpdateTime, tz = "Asia/Taipei"))
weather <- read.csv(xzfile("data/Weather_0424-0524.csv.xz")) %>%
  filter(Temp != -99, HUMD != -99) %>%
  mutate(ObsTime = ymd_hms(ObsTime, tz = "Asia/Taipei"))

availability <- availability %>%
  left_join(station_info %>% select(StationID = sno, latitude, longitude, area =
                                      sarea),
            by = "StationID") %>%
  left_join(station_info2 %>% select(StationID, lat2 = latitude, lon2 =
                                       longitude),
            by = "StationID") %>%
  mutate(
    latitude = ifelse(is.na(latitude), lat2, latitude),
    longitude = ifelse(is.na(longitude), lon2, longitude)
  ) %>% select(-lat2, -lon2)

station_locations <- availability %>%
  select(StationID, latitude, longitude) %>% distinct() %>%
  filter(!is.na(latitude), !is.na(longitude))
weather_locations <- weather %>%
  select(WeatherStationID = StationID, LatWGS84, LonWGS84) %>% distinct()

station_nearest_weather <- station_locations %>%
  rowwise() %>%
  mutate(NearestWeatherStationID = {
    bike_point <- c(longitude, latitude)
    weather_points <- as.matrix(weather_locations[, c("LonWGS84", "LatWGS84")])
    dists <- geosphere::distHaversine(bike_point, weather_points)
    weather_locations$WeatherStationID[which.min(dists)]
  }) %>% ungroup()

availability <- availability %>%
  left_join(station_nearest_weather,
            by = c("StationID", "latitude", "longitude")) %>%
  mutate(UpdateHour = floor_date(UpdateTime, "hour"))
weather <- weather %>% mutate(ObsHour = floor_date(ObsTime, "hour"))

combined <- availability %>%
  left_join(weather,
            by = c(
              "NearestWeatherStationID" = "StationID",
              "UpdateHour" = "ObsHour"
            )) %>%
  drop_na() %>%
  rename(UpdateTime = UpdateTime.x) %>%
  mutate(
    hour = hour(UpdateTime),
    weekday = wday(UpdateTime, label = TRUE),
    date = as.Date(UpdateTime),
    weekday_num = as.numeric(weekday)
  )

# === Load your TOTAL data ===
data_total <- read_csv("merged_final_output.csv")

# === SERVER ===
server <- function(input, output, session) {
  
  # Time Heatmap Page
  output$time_heatmap_map <- renderLeaflet({
    leaflet(options = leafletOptions(
      minZoom = 14,
      maxZoom = 18,
      maxBounds = list(list(24.97, 121.46), list(25.15, 121.63))
    )) |>
      addTiles() |>
      setView(121.54, 25.017, zoom = 16)
  })
  
  observe({
    bounds <- input$time_heatmap_map_bounds
    if (is.null(bounds)) {
      return()
    }
    
    filtered_stations <- station_list |> filter(
      latitude >= bounds$south,
      latitude <= bounds$north,
      longitude >= bounds$west,
      longitude <= bounds$east
    )
    
    leafletProxy("time_heatmap_map") |>
      clearMarkers() |>
      addMarkers(
        data = filtered_stations,
        lng = ~ longitude,
        lat = ~ latitude,
        layerId = ~ StationUID,
        popup = ~ sna
      )
  })
  
  output$time_heatmap <- renderPlot({
    th_filtered_data <- data |>
      filter(UID == input$time_heatmap_map_marker_click$id) |>
      complete(
        Date = unique(data$Date),
        Hour = 0:23,
        fill = list(Value = NA)
      ) |>
      mutate(Date_Factor = factor(Date, levels = sort(unique(data$Date), decreasing = TRUE)))
    
    ggplot(th_filtered_data,
           aes(
             x = Hour + 0.5,
             y = Date_Factor,
             fill = Value
           )) +
      geom_tile() +
      scale_fill_gradient2(
        limits = c(-1, 1),
        low = "red",
        mid = "white",
        high = "blue",
        na.value = "grey",
        name = "站點狀態\n",
        breaks = c(-1, 0, 1),
        labels = c("無車可借", "供需平衡", "無位可還")
      ) +
      scale_y_discrete(labels = format(ymd(
        levels(th_filtered_data$Date_Factor)
      ), "%Y/%m/%d")) +
      scale_x_continuous(breaks = 0:24) +
      labs(
        title = station_list |>
          filter(StationUID == input$time_heatmap_map_marker_click$id) |>
          pull(sna),
        x = "時間",
        y = "日期"
      ) +
      coord_fixed() +
      theme_minimal() +
      theme(
        plot.title = element_text(
          hjust = 0.5,
          size = 24,
          face = "bold"
        )
      )
  }) |> bindEvent(input$time_heatmap_map_marker_click)
  
  # Dashboard Page
  filtered_data <- reactive({
    data <- combined %>%
      filter((area == input$area | input$area == "All") &
               weekday %in% input$weekdays)
    if (input$station_id %in% data$StationID) {
      data %>% filter(StationID == input$station_id)
    } else {
      data
    }
  })
  
  output$hourlyPlot <- renderPlot({
    filtered_data() %>%
      group_by(hour) %>%
      summarise(
        Rent = mean(AvailableRentBikes),
        Return = mean(AvailableReturnBikes)
      ) %>%
      ggplot(aes(x = hour)) +
      geom_line(aes(y = Rent, color = "Rent"), size = 1) +
      geom_line(aes(y = Return, color = "Return"), size = 1) +
      scale_color_manual(values = c("Rent" = "#006400", "Return" = "#90EE90")) +
      labs(title = "Hourly Bike Availability", x = "Hour", y = "Count") +
      theme_minimal()
  })
  
  output$dailyTrendPlot <- renderPlot({
    daily <- filtered_data() %>%
      group_by(date) %>%
      summarise(
        Rent = mean(AvailableRentBikes),
        Return = mean(AvailableReturnBikes),
        Temp = mean(Temp),
        HUMD = mean(HUMD)
      )
    bike_range <- range(c(daily$Rent, daily$Return))
    daily <- daily %>% mutate(
      Temp_scaled = rescale(Temp, to = bike_range),
      HUMD_scaled = rescale(HUMD, to = bike_range)
    )
    ggplot(daily, aes(x = date)) +
      geom_line(aes(y = Rent, color = "Rent"), size = 1) +
      geom_line(aes(y = Return, color = "Return"), size = 1) +
      geom_line(aes(y = Temp_scaled, color = "Temp"), linetype = "dashed", size = 1) +
      geom_line(aes(y = HUMD_scaled, color = "Humidity"), linetype = "dashed", size = 1) +
      scale_color_manual(
        values = c(
          "Rent" = "#006400",
          "Return" = "#66CDAA",
          "Temp" = "#4169E1",
          "Humidity" = "#B0E0E6"
        )
      ) +
      labs(title = "Daily Trend: Rent / Return / Temperature / Humidity", x = "Date", y = "Value") +
      theme_minimal()
  })
  
  output$corrPlot <- renderPlot({
    num_cols <- c(
      "AvailableRentBikes",
      "AvailableReturnBikes",
      "hour",
      "weekday_num",
      "Temp",
      "HUMD"
    )
    corr_data <- filtered_data() %>% select(all_of(num_cols))
    corr_matrix <- cor(corr_data, method = "pearson", use = "complete.obs")
    colnames(corr_matrix) <- rownames(corr_matrix) <- c("Rent", "Return", "Hour", "Weekday", "Temp", "Humidity")
    ggcorrplot(corr_matrix, lab = TRUE, lab_size = 4)
  })
  
  output$summaryStats <- renderTable({
    filtered_data() %>%
      select(AvailableRentBikes, AvailableReturnBikes, Temp, HUMD) %>%
      summarise_all(list(mean = mean, sd = sd))
  })
  
  # === Total Map Page ===
  output$totalPlot <- renderPlot({
    selected_data <- data_total[data_total$day_of_year == input$day_slider & data_total$hour == input$hour_slider, ]
    total_max <- max(data_total$total, na.rm = TRUE)
    selected_data$color_value <- selected_data$total / total_max
    
    ggplot(selected_data, aes(x = longitude, y = latitude)) +
      geom_point(aes(color = color_value), size = 4, alpha = 0.5) +
      scale_color_gradient(low = "white", high = "red") +
      ggtitle(paste("Day of Year:", input$day_slider, " | Hour:", input$hour_slider)) +
      theme_minimal() +
      theme(plot.title = element_text(hjust = 0.5)) +
      labs(color = "Normalized Total")
  })
}

# === UI ===
ui <- page_navbar(
  theme = bs_theme(base_font = font_google("Roboto")),
  
  # Time Heatmap Page
  nav_panel(
    "Time Heatmap",
    fluidPage(
      titlePanel("Time Heatmap"),
      leafletOutput("time_heatmap_map"),
      plotOutput("time_heatmap", height = "auto")
    )
  ),
  
  # Dashboard Page
  nav_panel("Dashboard", fluidPage(
    theme = bs_theme(bootswatch = "minty"),
    titlePanel("YouBike + Weather Analysis Dashboard"),
    sidebarLayout(
      sidebarPanel(
        selectInput("station_id", "Select Station:", choices = unique(combined$StationID)),
        selectInput("area", "Select Area:", choices = c("All", unique(combined$area)), selected = "All"),
        checkboxGroupInput("weekdays", "Filter by Weekday:", choices = levels(combined$weekday), selected = levels(combined$weekday)),
        width = 3
      ),
      mainPanel(tabsetPanel(
        tabPanel("Hourly Trend", plotOutput("hourlyPlot")),
        tabPanel("Daily Trend + Weather", plotOutput("dailyTrendPlot")),
        tabPanel("Correlation Heatmap", plotOutput("corrPlot")),
        tabPanel("Summary Stats", fluidRow(
          column(6, h4("Summary Statistics"), tableOutput("summaryStats"))
        ))
      ))
    )
  )),
  
  # === New Total Map Page ===
  nav_panel(
    "Total Map",
    fluidPage(
      titlePanel("Total vs. Day and Hour (Red Intensity by Total)"),
      sidebarLayout(
        sidebarPanel(
          sliderInput("day_slider", "Select Day of Year:", min = min(data_total$day_of_year), max = max(data_total$day_of_year), value = min(data_total$day_of_year), step = 1, animate = animationOptions(interval = 500, loop = TRUE)),
          sliderInput("hour_slider", "Select Hour:", min = min(data_total$hour), max = max(data_total$hour), value = min(data_total$hour), step = 1, animate = animationOptions(interval = 500, loop = TRUE))
        ),
        mainPanel(
          plotOutput("totalPlot")
        )
      )
    )
  ),
  
  title = "YouBike"
)

# Run App
shinyApp(ui, server)

