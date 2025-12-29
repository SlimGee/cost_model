# app/controllers/calculations_controller.rb
class CalculationsController < ApplicationController
  def index
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
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @slicing_data = SlicingDatum.find(params[:id])
    @machine = @slicing_data.machine
    @material = @slicing_data.material
    @calculator = CostCalculator.new(@slicing_data)
    @params = GlobalParameter.current
    @global_params = GlobalParameter.current
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
      ]
    )
  end
end
