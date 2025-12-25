class CalculationsController < ApplicationController
  def index
    @machines = Machine.all
    @materials = Material.all
    @slicing_data = SlicingDatum.new
  end

  def create
    @slicing_data = SlicingDatum.new(slicing_data_params)

    if @slicing_data.save
      redirect_to calculation_path(@slicing_data), notice: "Analysis created successfully!"
    else
      @machines = Machine.all
      @materials = Material.all
      render :index, status: :unprocessable_entity
    end
  end

  def show
    @slicing_data = SlicingDatum.find(params[:id])
    @machine = @slicing_data.machine
    @material = @slicing_data.material
  end

  private

  def slicing_data_params
    params.require(:slicing_datum).permit(
      :part_name, :part_volume, :part_height, :surface_area,
      :support_volume, :layer_thickness, :parts_per_build,
      :material_utilization, :machine_id, :material_id
    )
  end
end
