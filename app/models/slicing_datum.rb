class SlicingDatum < ApplicationRecord
  belongs_to :machine
  belongs_to :material

  validates :part_name, presence: true
  validates :part_volume, presence: true, numericality: { greater_than: 0 }
  validates :part_height, presence: true, numericality: { greater_than: 0 }
  validates :surface_area, presence: true, numericality: { greater_than: 0 }
  validates :support_volume, numericality: { greater_than_or_equal_to: 0 }
  validates :layer_thickness, presence: true, numericality: { greater_than: 0 }
  validates :parts_per_build, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :material_utilization, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  before_save :calculate_derived_values

  def self.with_default_params
    params = GlobalParameter.current
    new(params.attributes.except(:id))
  end

  def effective_parameters
    if use_custom_parameters?
      GlobalParameter.new(
        electricity_rate: electricity_rate,
        labor_rate: labor_rate,
        annual_operating_hours: annual_operating_hours,
        inert_gas_price: inert_gas_price,
        gas_consumption_per_hour: gas_consumption_per_hour,
        annual_rent: annual_rent,
        annual_utilities: annual_utilities,
        annual_admin: annual_admin,
        annual_software_cost: annual_software_cost,
        annual_hpc_cost: annual_hpc_cost,
        preventive_maintenance_frequency: preventive_maintenance_frequency,
        preventive_maintenance_cost: preventive_maintenance_cost,
        corrective_maintenance_frequency: corrective_maintenance_frequency,
        corrective_maintenance_cost: corrective_maintenance_cost,
        grid_emission_factor: grid_emission_factor,
        waste_disposal_cost_per_kg: waste_disposal_cost_per_kg,
        machine_power_consumption: machine_power_consumption,
        setup_time_hours: setup_time_hours,
        post_processing_time_per_part: post_processing_time_per_part
      )
    else
      GlobalParameter.current
    end
  end

  private

  def calculate_derived_values
    # Calculate part mass: M_part = V_part * ρ
    # Convert volume from mm³ to cm³ (divide by 1000) for density in g/cm³
    part_volume_cm3 = part_volume / 1000.0
    support_volume_cm3 = (support_volume || 0) / 1000.0
    total_volume_cm3 = part_volume_cm3 + support_volume_cm3

    # Mass in grams, convert to kg
    self.part_mass = (total_volume_cm3 * material.density) / 1000.0

    # Calculate total powder mass: M_total = M_part / η (utilization efficiency)
    self.total_powder_mass = part_mass / material_utilization

    # Estimate build time (simplified for now)
    # Build time is roughly proportional to volume and layer count
    layer_count = part_height / layer_thickness
    # Rough estimate: 5 seconds per layer + volume factor
    self.build_time_hours = ((layer_count * 5) / 3600.0) + (part_volume / 100_000.0)
  end
end
