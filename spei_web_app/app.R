
library(shiny)
library(SPEI)
library(data.table)
library(lubridate)

ui <- fluidPage(
  titlePanel("Calcul des indices SPEI"),
  
  p("Importez les donnees meteorologiques quotidiennes au format CSV."),
  
  fileInput(
    "climate_file",
    "Fichier meteorologique CSV",
    accept = ".csv"
  ),
  
  numericInput(
    "latitude",
    "Latitude (degres)",
    value = 45.74,
    min = -90,
    max = 90
  ),
  
  actionButton("calculate", "Calculer les indices SPEI"),
  
  br(), br(),
  
  verbatimTextOutput("status"),
  
  downloadButton(
    "download",
    "Telecharger climate_spei.csv"
  )
)

server <- function(input, output, session) {
  
  result <- eventReactive(input$calculate, {
    
    req(input$climate_file)
    
    # Lire le CSV avec separateur point-virgule
    climate <- read.csv2(
      input$climate_file$datapath,
      stringsAsFactors = FALSE
    )
    
    # Verifier les colonnes necessaires
    required <- c("date", "Prec", "Tmax", "Tmin")
    
    if (!all(required %in% names(climate))) {
      stop(
        paste(
          "Colonnes requises :",
          paste(required, collapse = ", ")
        )
      )
    }
    
    # Convertir les dates
    climate$date <- as.Date(
      climate$date,
      format = "%d/%m/%Y"
    )
    
    if (anyNA(climate$date)) {
      stop("Certaines dates sont invalides. Format attendu : JJ/MM/AAAA.")
    }
    
    climate <- climate[order(climate$date), ]
    
    # Convertir les variables numeriques
    climate$Prec <- as.numeric(climate$Prec)
    climate$Tmax <- as.numeric(climate$Tmax)
    climate$Tmin <- as.numeric(climate$Tmin)
    
    if (any(!is.finite(as.matrix(
      climate[, c("Prec", "Tmax", "Tmin")]
    )))) {
      stop("Les variables meteo contiennent des valeurs manquantes ou invalides.")
    }
    
    # Temperature moyenne et amplitude thermique
    climate$Tmean <- (climate$Tmax + climate$Tmin) / 2
    
    climate$T_diff <- pmax(
      climate$Tmax - climate$Tmin,
      0
    )
    
    climate$lat <- input$latitude
    
    # Charger la fonction PET fournie avec l'application
    source("HargreavesPET_daily.R", local = TRUE)
    
    climate$PET <- HargreavesPET_daily(
      date = climate$date,
      tavg = climate$Tmean,
      tdif = climate$T_diff,
      lat = climate$lat
    )
    
    # Bilan hydrique
    climate$balance <- climate$Prec - climate$PET
    
    climate$year_month <- format(
      climate$date,
      "%Y-%m"
    )
    
    # Agregation mensuelle
    monthly_balance <- aggregate(
      balance ~ year_month,
      data = climate,
      sum
    )
    
    # Verifier la continuite des mois
    month_dates <- as.Date(
      paste0(monthly_balance$year_month, "-01")
    )
    
    expected_months <- seq(
      min(month_dates),
      max(month_dates),
      by = "month"
    )
    
    if (!identical(
      as.character(month_dates),
      as.character(expected_months)
    )) {
      stop("La serie doit contenir tous les mois consecutifs.")
    }
    
    if (nrow(monthly_balance) < 6) {
      stop("Il faut au minimum six mois de donnees.")
    }
    
    balance_ts <- ts(
      monthly_balance$balance,
      start = c(
        year(month_dates[1]),
        month(month_dates[1])
      ),
      frequency = 12
    )
    
    # Calcul des SPEI
    spei_1 <- SPEI::spei(
      balance_ts, scale = 1, na.rm = TRUE
    )
    
    spei_3 <- SPEI::spei(
      balance_ts, scale = 3, na.rm = TRUE
    )
    
    spei_6 <- SPEI::spei(
      balance_ts, scale = 6, na.rm = TRUE
    )
    
    climate_spei <- data.table(
      year_month = monthly_balance$year_month,
      spei_1 = as.numeric(fitted(spei_1)),
      spei_3 = as.numeric(fitted(spei_3)),
      spei_6 = as.numeric(fitted(spei_6))
    )
    
    climate_spei[, year_month :=
                   as.integer(
                     format(
                       as.Date(paste0(year_month, "-01")),
                       "%Y%m%d"
                     )
                   )
    ]
    
    climate_spei
  })
  
  output$status <- renderText({
    if (input$calculate == 0) {
      return("Importez un fichier, puis cliquez sur Calculer.")
    }
    
    tryCatch({
      nrow(result())
      "Calcul termine. Le fichier est pret a etre telecharge."
    }, error = function(e) {
      paste("Erreur :", conditionMessage(e))
    })
  })
  
  output$download <- downloadHandler(
    filename = function() {
      "climate_spei.csv"
    },
    
    content = function(file) {
      fwrite(result(), file)
    }
  )
}

shinyApp(ui = ui, server = server)
