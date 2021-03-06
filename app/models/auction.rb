class Auction < ActiveRecord::Base
  attr_accessible :seller, :item, :buy_it_now_price, :status, :end_date, :extendable

  belongs_to :item
  belongs_to :winner, :class_name => 'User'
  belongs_to :seller, :class_name => 'User'
  has_many :bids

  PENDING = 'pending'
  STARTED = 'started'
  CLOSED = 'closed'
  CANCELED = 'canceled'
  validates :status, inclusion: {in: [PENDING, STARTED, CLOSED, CANCELED]}

  validates :item, presence: true
  validates :seller, presence: true
  validates :end_date, presence: true
  validates :buy_it_now_price, :numericality => true

  validate :buyer_and_seller_are_different
  validate :end_date_period

  def start
    self.status = STARTED
    save!
  end

  def close
    self.status = CLOSED
    save!
  end

  def started?
    status == STARTED
  end

  def last_bid
    bids.last
  end

  def extend_end_date_for interval
    self.end_date = interval.since self.end_date
    save!
  end

  def assign_winner bidder
    self.winner = bidder
    close
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidRecordException.new(e.record.errors.full_messages)
  end

  def make_bid bidder, amount
    bids.create! user: bidder, amount: amount
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidRecordException.new(e.record.errors.full_messages)
  end

  def self.make attrs
    create! attrs.merge(status: PENDING)
  rescue ActiveRecord::RecordInvalid => e
    raise InvalidRecordException.new(e.record.errors.full_messages)
  end

  private

  def end_date_period
    errors.add(:end_date, "must be in the future") if end_date && end_date < DateTime.current
  end

  def buyer_and_seller_are_different
    errors.add(:base, "can't be equal to seller") if seller_id == winner_id
  end
end
