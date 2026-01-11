# app/services/cost_calculator.rb
class CostCalculator
  attr_reader :slicing_data, :machine, :material, :params

  def initialize(slicing_data)
    @slicing_data = slicing_data
    @machine = slicing_data.machine
    @material = slicing_data.material
    @params = slicing_data.effective_parameters
  end

  # ========== LINE ITEM BASED COSTS ==========

  def labor_cost_per_build
    slicing_data.total_labor_cost_per_build
  end

  def consumables_cost_per_build
    slicing_data.total_consumables_cost_per_build
  end

  def energy_cost_per_build
    slicing_data.total_energy_cost_per_build
  end

  def equipment_cost_per_build
    slicing_data.total_equipment_cost_per_build
  end

  def facility_cost_per_build
    slicing_data.total_facility_cost_per_build
  end

  def digital_cost_per_build
    slicing_data.total_digital_cost_per_build
  end

  def maintenance_cost_per_build
    slicing_data.total_maintenance_cost_per_build
  end

  def total_cost_per_build
    slicing_data.total_cost_from_line_items_per_build
  end

  def total_cost_per_part
    slicing_data.total_cost_from_line_items_per_part
  end

  # ========== INDIVIDUAL LINE ITEM ACCESSORS ==========

  def labor_line_items
    slicing_data.cost_line_items.labor_items.ordered
  end

  def consumable_line_items
    slicing_data.cost_line_items.consumable_items.ordered
  end

  def energy_line_items
    slicing_data.cost_line_items.energy_items.ordered
  end

  def equipment_line_items
    slicing_data.cost_line_items.equipment_items.ordered
  end

  def facility_line_items
    slicing_data.cost_line_items.facility_items.ordered
  end

  def digital_line_items
    slicing_data.cost_line_items.digital_items.ordered
  end

  def maintenance_line_items
    slicing_data.cost_line_items.maintenance_items.ordered
  end

  # ========== DERIVED METRICS (still calculated, not from line items) ==========

  def powder_cost_per_build
    powder_items = consumable_line_items.where("name LIKE ?", "%Powder%")
    powder_items.sum(&:total_per_build)
  end

  def gas_cost_per_build
    gas_items = consumable_line_items.where("name LIKE ?", "%Gas%")
    gas_items.sum(&:total_per_build)
  end

  def waste_cost_per_build
    waste_items = consumable_line_items.where("name LIKE ?", "%Waste%")
    waste_items.sum(&:total_per_build)
  end

  def setup_cost
    setup_items = labor_line_items.where("name LIKE ?", "%Setup%")
    setup_items.sum(&:total_per_build)
  end

  def operator_time
    labor_line_items.sum(:quantity)
  end

  # ========== SUSTAINABILITY METRICS ==========

  def energy_consumption
    # Sum all energy line items
    energy_line_items.sum(:quantity)
  end

  def recycled_powder_mass
    unused_powder = slicing_data.total_powder_mass - slicing_data.part_mass
    unused_powder * material.recycling_efficiency
  end

  def non_recycled_powder_mass
    slicing_data.total_powder_mass - slicing_data.part_mass - recycled_powder_mass
  end

  def carbon_footprint_energy
    energy_consumption * params.grid_emission_factor
  end

  def carbon_footprint_material
    slicing_data.part_mass * material.embodied_carbon
  end

  def carbon_footprint_digital
    digital_energy = slicing_data.build_time_hours * 0.5
    digital_energy * params.grid_emission_factor
  end

  def total_carbon_footprint
    carbon_footprint_energy + carbon_footprint_material + carbon_footprint_digital
  end

  def carbon_footprint_per_kg
    total_carbon_footprint / slicing_data.part_mass
  end

  def waste_ratio
    (slicing_data.total_powder_mass - slicing_data.part_mass - recycled_powder_mass) /
      slicing_data.total_powder_mass
  end

  def recycling_efficiency
    recycled_powder_mass / slicing_data.total_powder_mass
  end

  def energy_efficiency_per_kg
    energy_consumption / slicing_data.part_mass
  end

  def consumables_cost_per_kg
    consumables_cost_per_build / (slicing_data.part_mass * slicing_data.parts_per_build)
  end

  # ========== BREAKDOWN FOR VISUALIZATION ==========

  def cost_breakdown
    {
      consumables: consumables_cost_per_build,
      energy: energy_cost_per_build,
      equipment: equipment_cost_per_build,
      labor: labor_cost_per_build,
      facility: facility_cost_per_build,
      digital: digital_cost_per_build,
      maintenance: maintenance_cost_per_build
    }
  end

  def cost_breakdown_percentages
    total = total_cost_per_build
    return {} if total.zero?

    cost_breakdown.transform_values { |v| (v / total * 100).round(1) }
  end

  def detailed_cost_breakdown_by_category
    {
      labor: labor_line_items.map { |item| line_item_hash(item) },
      consumables: consumable_line_items.map { |item| line_item_hash(item) },
      energy: energy_line_items.map { |item| line_item_hash(item) },
      equipment: equipment_line_items.map { |item| line_item_hash(item) },
      facility: facility_line_items.map { |item| line_item_hash(item) },
      digital: digital_line_items.map { |item| line_item_hash(item) },
      maintenance: maintenance_line_items.map { |item| line_item_hash(item) }
    }
  end

  private

  def line_item_hash(item)
    {
      name: item.name,
      description: item.description,
      unit_cost: item.unit_cost,
      quantity: item.quantity,
      unit_type: item.unit_type,
      total_per_build: item.total_per_build,
      total_per_part: item.total_per_part
    }
  end
end
