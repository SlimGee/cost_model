# app/controllers/calculations_controller.rb
class CalculationsController < ApplicationController
  def index
    @slicing_data = SlicingDatum.order(created_at: :desc)
    @analyses = @slicing_data
  end

  def new
    @machines = Machine.all
    @materials = Material.all
    @slicing_data = SlicingDatum.with_default_params
    @global_params = GlobalParameter.current
  end

  def create
    @slicing_data = SlicingDatum.new(slicing_data_params)

    if @slicing_data.save
      redirect_to calculation_path(@slicing_data), notice: "Analysis created successfully!"
    else
      @machines = Machine.all
      @materials = Material.all
      @global_params = GlobalParameter.current
      render :new, status: :unprocessable_content
    end
  end

  def show
    @slicing_data = SlicingDatum.find(params[:id])
    @machine = @slicing_data.machine
    @material = @slicing_data.material
    @calculator = CostCalculator.new(@slicing_data)
    @financial_analyzer = FinancialAnalyzer.new(@slicing_data, @calculator)
    @params = @slicing_data.effective_parameters
    @global_params = GlobalParameter.current

    # Run Monte Carlo simulation
    iterations = @params.monte_carlo_iterations || 10_000
    @monte_carlo = MonteCarloSimulator.new(@slicing_data, iterations: iterations)
    @monte_carlo.run!
  end

  private

  def slicing_data_params
    params.expect(
      slicing_datum: %i[
        part_name
        part_volume
        part_height
        surface_area
        support_volume
        layer_thickness
        parts_per_build
        material_utilization
        machine_id
        material_id
        use_custom_parameters
        electricity_rate
        labor_rate
        annual_operating_hours
        inert_gas_price
        gas_consumption_per_hour
        annual_rent
        annual_utilities
        annual_admin
        annual_software_cost
        annual_hpc_cost
        grid_emission_factor
        waste_disposal_cost_per_kg
        machine_power_consumption
        setup_time_hours
        post_processing_time_per_part
        preventive_maintenance_cost
        preventive_maintenance_frequency
        corrective_maintenance_cost
        corrective_maintenance_frequency
        price_per_part
        discount_rate
        analysis_horizon_years
        upfront_investment
        machine_utilization_rate
        minimum_acceptable_return
        cost_volatility
        revenue_volatility
        monte_carlo_iterations
      ]
    )
  end
end
