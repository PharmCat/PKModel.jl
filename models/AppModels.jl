module AppModels

using Stipple,  StipplePlotly
using GenieAutoReload
using DifferentialEquations
export AppModel

@reactive mutable struct AppModel <: ReactiveModel
  time::R{Float64} = 24.0
  dose::R{Float64} = 100.0
  v1::R{Float64} = 50.0
  v2::R{Float64} = 50.0
  Kabs::R{Float64} = 0.3
  Kel::R{Float64} = 0.2
  K12::R{Float64} = 0.4
  K21::R{Float64} = 0.1
  resample::R{Bool} = false
  plots_data::R{Vector{PlotData}}   = [PlotData(x = [1,2,3], y = [1,1,1])]
  plotsio_data::R{Vector{PlotData}} = [PlotData(x = [1,2,3], y = [1,1,1])]
end

heaviside(x) = ifelse(x < 0, zero(x), ifelse(x > 0, one(x), oftype(x, 0.5)))

function modelfunc!(du, u, p, t)
  Kabs, K12, K21, Kel, Vf , Vp = p
  Vr = Vf/Vp
  du01 = Kabs * u[1]
  du12 = K12 * (u[2] - u[3]) * heaviside(u[2] - u[3])
  du21 = K21 * (u[3] - u[2]) * heaviside(u[3] - u[2])
  du10 = Kel * u[2]
  du[1] = -du01
  du[2] = du01 / Vf - du12 + du21 / Vr - du10
  du[3] = du12 * Vr - du21
  du[4] = du10 * Vf
end

function plotmodel(model) 
  u0 = [model.dose[], 0.0, 0.0, 0.0]
  tspan = (0.0, model.time[])
  prob = ODEProblem(modelfunc!, u0, tspan, [model.Kabs[], model.K12[], model.K21[], model.Kel[], model.v1[], model.v2[]])
  sol = solve(prob)
  x_ = 0.0:model.time[]/100:model.time[]
  x = collect(x_)
  plt = ([PlotData(x = x, y = getindex.(sol(x_).u, 1), name = "K0"), PlotData(x = x, y = getindex.(sol(x_).u, 4), name = "Eliminated")], 
  [PlotData(x = x, y = getindex.(sol(x_).u, 2), name = "K1"), PlotData(x = x, y = getindex.(sol(x_).u, 3), name = "K2")])
  #PlotData(x = x, y = getindex.(sol(x_).u, 2), name = "K1")
  plt
end

function handlers(model::AppModel) :: AppModel
  #=
  on(model.message) do message
    model.isprocessing = true
    model.message[] = "Hello to you too!"
    model.isprocessing = false
  end
  =#
  on(model.resample) do resample
    if resample
      @info "this worked"
      #model.plot_data[] = PlotData(x = [1, 2, 3,6,5,4], y = [4, 5, 6,8,7,6])
      model.plotsio_data[], model.plots_data[] = plotmodel(model) 
      model.resample[] = false
    end
  end
  model
end


end

