class GlobalParameter < ApplicationRecord
  validates :electricity_rate, :labor_rate, :annual_operating_hours,
            presence: true, numericality: { greater_than: 0 }

  # Singleton pattern - only one set of global parameters
  def self.current
    first_or_create
  end

  def facility_cost_per_hour
    (annual_rent + annual_utilities + annual_admin) / annual_operating_hours
  end

  def digital_cost_per_hour
    (annual_software_cost + annual_hpc_cost) / annual_operating_hours
  end

  def total_annual_maintenance
    (preventive_maintenance_frequency * preventive_maintenance_cost) +
      (corrective_maintenance_frequency * corrective_maintenance_cost)
  end
end
