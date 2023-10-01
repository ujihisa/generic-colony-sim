# frozen_string_literal: true

module Action
  def self.available_actions(g)
    available = [
      :dig_raw_mineral!,
      :harvest_wild_plant!,
      :expand_farm!,
      :run_manual_generator!,
    ]
    if 1 <= g.storage[:algae]
      available += [:run_manual_oxygen_diffuser!]
    end
    if g.housing_level < Game::HOUSING_COST.size && Game::HOUSING_COST[g.housing_level].all? {|k, m| g.storage[k] >= m }
      available += [:improve_housing!]
    end
    available
  end

  module DigRawMineral
    def self.cost(_)
      {
        raw_mineral: 3,
        fertilizer: 1,
        algae: 1,
      }
    end

    def self.do!(g)
      g.dig_raw_mineral_distance += 1
    end

    def self.tick(g)
      1.0 + g.dig_raw_mineral_distance * 0.1
    end
  end

  module HarvestWildPlant
    def self.cost(_)
      {}
    end

    def self.do!(g)
      g.harvest_wild_plant_distance += 1
      g.stored_food += 3
      if 10 < g.stored_food
        p("Too much stored food. Discarded #{g.stored_food - 10}")
        g.stored_food = 10
      end

    end

    def self.tick(g)
      1.0 + g.harvest_wild_plant_distance ** 2
    end
  end
end
