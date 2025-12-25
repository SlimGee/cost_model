# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb

# Clear existing data
Machine.destroy_all
Material.destroy_all

puts "Creating machines..."

Machine.create!([
  {
    name: "SLM 280",
    model_number: "SLM280",
    build_volume_x: 280.0,
    build_volume_y: 280.0,
    build_volume_z: 365.0,
    laser_power: 400.0,
    scan_speed: 7000.0,
    purchase_price: 750000.0,
    lifespan_years: 7,
    annual_maintenance_cost: 50000.0
  },
  {
    name: "SLM 500",
    model_number: "SLM500",
    build_volume_x: 500.0,
    build_volume_y: 280.0,
    build_volume_z: 365.0,
    laser_power: 700.0,
    scan_speed: 10000.0,
    purchase_price: 1200000.0,
    lifespan_years: 7,
    annual_maintenance_cost: 75000.0
  },
  {
    name: "EOS M290",
    model_number: "M290",
    build_volume_x: 250.0,
    build_volume_y: 250.0,
    build_volume_z: 325.0,
    laser_power: 400.0,
    scan_speed: 7000.0,
    purchase_price: 800000.0,
    lifespan_years: 7,
    annual_maintenance_cost: 55000.0
  }
])

puts "Created #{Machine.count} machines"

puts "Creating materials..."

Material.create!([
  {
    name: "Titanium Ti-6Al-4V",
    code: "Ti-6Al-4V",
    density: 4.43,
    raw_material_price: 350.0,
    embodied_carbon: 35.0,
    recycling_efficiency: 0.90
  },
  {
    name: "Aluminum AlSi10Mg",
    code: "AlSi10Mg",
    density: 2.67,
    raw_material_price: 45.0,
    embodied_carbon: 8.5,
    recycling_efficiency: 0.92
  },
  {
    name: "Stainless Steel 316L",
    code: "316L",
    density: 7.99,
    raw_material_price: 85.0,
    embodied_carbon: 6.2,
    recycling_efficiency: 0.88
  },
  {
    name: "Inconel 718",
    code: "IN718",
    density: 8.19,
    raw_material_price: 280.0,
    embodied_carbon: 42.0,
    recycling_efficiency: 0.85
  }
])

puts "Created #{Material.count} materials"
puts "Seed data created successfully!"
