class Reservation < ApplicationRecord
  SEAT_PREFERENCES = [
    'Indifférent',
    'Fenêtre',
    'Couloir',
    'Côte à côte',
    'Haut',
    'Bas',
    'Haut, fenêtre',
    'Haut, couloir',
    'Haut, côte à côte',
    'Bas, fenêtre',
    'Bas, couloir',
    'Bas, côte à côte',
    'À côté de',
  ].freeze

  belongs_to :user, counter_cache: true

  validates :city_departure, presence: true
  validates :city_arrival, presence: true
  validates :date_departure, presence: true
  validates :time_departure, presence: true
  validates :seat_preference, inclusion: { in: SEAT_PREFERENCES }

  before_save :sanitize_cities

  state_machine :state, initial: :pending do
    event :process do
      transition [:pending, :failed] => :processing
    end

    event :failure do
      transition processing: :failed
    end

    event :success do
      transition processing: :successful
    end
  end

  scope :unbooked, -> { where(state: [:pending, :failed], date_departure: Date.current + 1.day..Date.current + 1.day + 1.month) }

  private

  def sanitize_cities
    self.city_departure = self.city_departure.split(',').first
    self.city_arrival = self.city_arrival.split(',').first
  end
end
