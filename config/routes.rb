Rails.application.routes.draw do
  get "pages/info"
  root "home#index"
  get "dashboard", to: "dashboard#index"

  # CRUD dinámico usando TablasController
  get    "/tablas/:tabla",             to: "tablas#tabla"
  post   "/tablas/:tabla/create",      to: "tablas#create"
  patch  "/tablas/:tabla/update/:id",  to: "tablas#update"
  delete "/tablas/:tabla/delete/:id",  to: "tablas#delete"
end