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
        post_processing_time_per_part: post_processing_time_per_part,

        price_per_part: price_per_part,
        discount_rate: discount_rate,
        analysis_horizon_years: analysis_horizon_years,
        upfront_investment: upfront_investment,
        machine_utilization_rate: machine_utilization_rate,
        minimum_acceptable_return: minimum_acceptable_return,
        # Monte Carlo parameters
        cost_volatility: cost_volatility,
        revenue_volatility: revenue_volatility,
        monte_carlo_iterations: monte_carlo_iterations
      )
    else
      GlobalParameter.current
    end
  end

  def build_time_hours_per_build
    build_time_hours * parts_per_build
  end

  HATCH_SPACING_MM = 0.1 # Typical hatch spacing in mm
  RECOATING_TIME_PER_LAYER_SECONDS = 10 # Typical recoating time per layer in seconds

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

    calculate_single_part_build_time
  end

  def calculate_single_part_build_time
    return unless machine && part_height && layer_thickness && part_volume && support_volume && parts_per_build

    # Total volume to melt (mm³)
    total_volume_mm3 = (part_volume + support_volume) * parts_per_build

    # Number of layers (assuming height doesn't increase with multiple parts)
    num_layers = (part_height / layer_thickness).ceil

    # Scanning time (seconds)
    build_rate_mm3_per_s = layer_thickness * HATCH_SPACING_MM * machine.scan_speed
    scanning_time_s = total_volume_mm3 / build_rate_mm3_per_s

    # Recoating time (seconds)
    recoating_time_s = num_layers * RECOATING_TIME_PER_LAYER_SECONDS

    # Total build time (hours)
    self.build_time_hours = (scanning_time_s + recoating_time_s) / 3600.0
  end
end
