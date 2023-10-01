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
end
