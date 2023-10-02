# frozen_string_literal: true

module Action
  def self.available_actions(g)
    available = Action.constants.map { const_get(_1) }.select {|action_mod|
      if action_mod.singleton_class.method_defined?(:prohibited) && action_mod.prohibited(g)
        next false
      end

      cost = action_mod.new.cost(g)
      cost.fetch(:storage, {}).all? {|k, amount|
        amount <= g.storage[k]
      }
    }
    available
  end

  class DigRawMineral
    TARGETS = [
      :default,
    ].freeze

    def cost(_)
      {
      }
    end

    def do!(g)
      g.dig_raw_mineral_distance += 1

      {
        raw_mineral: 3,
        fertilizer: 1,
        algae: 1,
      }.each do |k, amount|
        g.put_storage!(k, amount)
      end
    end

    def tick(g)
      1.0 + g.dig_raw_mineral_distance * 0.1
    end
  end

  class HarvestWildPlant
    TARGETS = [
      :default,
    ].freeze

    def cost(_)
      {}
    end

    def do!(g)
      g.harvest_wild_plant_distance += 1
      g.stored_food += 3
      if 10 < g.stored_food
        p("Too much stored food. Discarded #{g.stored_food - 10}")
        g.stored_food = 10
      end

    end

    def tick(g)
      1.0 + g.harvest_wild_plant_distance ** 2
    end
  end

  class RunManualOxygenDiffuser
    TARGETS = [
      :default,
    ].freeze

    def cost(_)
      {
        storage: {
          algae: 1,
        },
      }
    end

    def do!(g)
      g.oxygen_pressure += 1.0
    end

    def tick(g)
      2.0
    end
  end

  class RunManualGenerator
    TARGETS = [
      :default,
    ].freeze

    def cost(_)
      {}
    end

    def do!(g)
      g.power += 400
    end

    def tick(g)
      1.0
    end
  end

  class ExpandFarm
    TARGETS = [
      :default,
    ].freeze

    def cost(_)
      {}
    end

    def do!(g)
      g.farm_size += 1
    end

    def tick(g)
      2.0
    end
  end

  class ImproveHousing
    TARGETS = [
      :default,
    ].freeze

    HOUSING_COST = {
      1 => {
        raw_mineral: 6,
      },
      2 => {
        raw_mineral: 12,
      },
      # 3 => {
      #   raw_mineral: 24,
      # },
      # 4 => {
      #   raw_mineral: 48,
      # },
    }.freeze

    def prohibited(g)
      HOUSING_COST.size <= g.housing_level
    end

    def cost(g)
      {
        storage: HOUSING_COST[g.housing_level],
      }
    end

    def do!(g)
      g.housing_level += 1
    end

    def tick(g)
      3.0
    end
  end

  class BuildBuilding
    TARGETS = [
      :default,
    ].freeze

    def cost(g)
      # TODO
      {}
    end

    def do!(g)
      # TODO
    end

    def tick(g)
      # TODO
      1.0
    end
  end
end
