class SlicingDatum < ApplicationRecord
  belongs_to :machine
  belongs_to :material
  has_many :cost_line_items, dependent: :destroy

  # Enable nested attributes for line items
  accepts_nested_attributes_for :cost_line_items,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :part_name, presence: true
  validates :part_volume, presence: true, numericality: { greater_than: 0 }
  validates :part_height, presence: true, numericality: { greater_than: 0 }
  validates :surface_area, presence: true, numericality: { greater_than: 0 }
  validates :support_volume, numericality: { greater_than_or_equal_to: 0 }
  validates :layer_thickness, presence: true, numericality: { greater_than: 0 }
  validates :parts_per_build, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :material_utilization, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  before_save :calculate_derived_values
  after_save :create_default_line_items, if: :needs_default_line_items?

  def self.with_default_params
    params = GlobalParameter.current
    new(params.attributes.except(:id))
  end

  # Build default line items without saving (for new form)
  def build_default_line_items
    return if cost_line_items.any?

    params = effective_parameters

    # Labor line items (3)
    cost_line_items.build(
      category: "labor",
      name: "Setup Labor",
      description: "Machine setup and preparation",
      unit_cost: params.labor_rate || 350,
      quantity: params.setup_time_hours || 2,
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )

    cost_line_items.build(
      category: "labor",
      name: "Build Supervision",
      description: "Operator supervision during build",
      unit_cost: params.labor_rate || 350,
      quantity: 1, # Will be filled when build time is calculated
      unit_type: "hours",
      is_per_build: true,
      position: 2
    )

    cost_line_items.build(
      category: "labor",
      name: "Post-Processing Labor",
      description: "Part removal, cleaning, finishing",
      unit_cost: params.labor_rate || 350,
      quantity: params.post_processing_time_per_part || 0.5,
      unit_type: "hours",
      is_per_build: false,
      position: 3
    )

    # Consumables line items (3)
    cost_line_items.build(
      category: "consumables",
      name: "Metal Powder",
      description: "Primary build material",
      unit_cost: 1200, # Default Ti-6Al-4V price
      quantity: 1, # Will be calculated
      unit_type: "kg",
      is_per_build: false,
      position: 1
    )

    cost_line_items.build(
      category: "consumables",
      name: "Inert Gas (Argon/N2)",
      description: "Build chamber atmosphere",
      unit_cost: params.inert_gas_price || 15,
      quantity: 1, # Will be calculated from build time
      unit_type: "m³",
      is_per_build: true,
      position: 2
    )

    cost_line_items.build(
      category: "consumables",
      name: "Waste Disposal",
      description: "Non-recyclable powder disposal",
      unit_cost: params.waste_disposal_cost_per_kg || 5,
      quantity: 1, # Will be calculated
      unit_type: "kg",
      is_per_build: false,
      position: 3
    )

    # Energy line items (1)
    cost_line_items.build(
      category: "energy",
      name: "Electrical Energy",
      description: "Machine power consumption",
      unit_cost: params.electricity_rate || 2.5,
      quantity: 1, # Will be calculated
      unit_type: "kWh",
      is_per_build: true,
      position: 1
    )

    # Equipment line items (1)
    cost_line_items.build(
      category: "equipment",
      name: "Machine Depreciation",
      description: "Equipment amortization",
      unit_cost: 0, # Will be calculated from machine
      quantity: 1, # Build time hours
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )

    # Facility line items (3)
    cost_line_items.build(
      category: "facility",
      name: "Facility Rent",
      description: "Allocated facility rent",
      unit_cost: (params.annual_rent || 360_000) / (params.annual_operating_hours || 2000),
      quantity: 1, # Build time
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )

    cost_line_items.build(
      category: "facility",
      name: "Utilities",
      description: "Water, HVAC, general power",
      unit_cost: (params.annual_utilities || 240_000) / (params.annual_operating_hours || 2000),
      quantity: 1, # Build time
      unit_type: "hours",
      is_per_build: true,
      position: 2
    )

    cost_line_items.build(
      category: "facility",
      name: "Administrative Overhead",
      description: "Admin, insurance, general overhead",
      unit_cost: (params.annual_admin || 180_000) / (params.annual_operating_hours || 2000),
      quantity: 1, # Build time
      unit_type: "hours",
      is_per_build: true,
      position: 3
    )

    # Digital line items (2)
    cost_line_items.build(
      category: "digital",
      name: "Software Licenses",
      description: "CAD, slicing, simulation software",
      unit_cost: (params.annual_software_cost || 120_000) / (params.annual_operating_hours || 2000),
      quantity: 1, # Build time
      unit_type: "hours",
      is_per_build: true,
      position: 1
    )

    cost_line_items.build(
      category: "digital",
      name: "HPC Systems",
      description: "High-performance computing",
      unit_cost: (params.annual_hpc_cost || 80_000) / (params.annual_operating_hours || 2000),
      quantity: 1, # Build time
      unit_type: "hours",
      is_per_build: true,
      position: 2
    )

    # Maintenance line items (2)
    cost_line_items.build(
      category: "maintenance",
      name: "Preventive Maintenance",
      description: "Scheduled maintenance activities",
      unit_cost: (params.preventive_maintenance_cost || 15_000) / [ params.preventive_maintenance_frequency || 12,
                                                                    1 ].max,
      quantity: 1,
      unit_type: "per_build",
      is_per_build: true,
      position: 1
    )

    cost_line_items.build(
      category: "maintenance",
      name: "Corrective Maintenance",
      description: "Repair and corrective actions",
      unit_cost: (params.corrective_maintenance_cost || 25_000) / [ params.corrective_maintenance_frequency || 6,
                                                                    1 ].max,
      quantity: 1,
      unit_type: "per_build",
      is_per_build: true,
      position: 2
    )
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

  # Aggregated line item costs
  def total_labor_cost_per_build
    cost_line_items.labor_items.sum(&:total_per_build)
  end

  def total_consumables_cost_per_build
    cost_line_items.consumable_items.sum(&:total_per_build)
  end

  def total_energy_cost_per_build
    cost_line_items.energy_items.sum(&:total_per_build)
  end

  def total_equipment_cost_per_build
    cost_line_items.equipment_items.sum(&:total_per_build)
  end

  def total_facility_cost_per_build
    cost_line_items.facility_items.sum(&:total_per_build)
  end

  def total_digital_cost_per_build
    cost_line_items.digital_items.sum(&:total_per_build)
  end

  def total_maintenance_cost_per_build
    cost_line_items.maintenance_items.sum(&:total_per_build)
  end

  def total_cost_from_line_items_per_build
    cost_line_items.sum(&:total_per_build)
  end

  def total_cost_from_line_items_per_part
    total_cost_from_line_items_per_build / parts_per_build
  end

  def needs_default_line_items?
    cost_line_items.empty? && persisted?
  end

  def create_default_line_items
    DefaultLineItemsCreator.new(self).create
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
