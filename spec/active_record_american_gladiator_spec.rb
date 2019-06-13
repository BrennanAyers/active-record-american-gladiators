require "rails_helper"

describe "ActiveRecord American Gladiator" do
  context "Joust" do
    it "loads all items" do
      Item.create(name: "Pugil Sticks")
      Item.create(name: "Trap Door")
      Item.create(name: "Crash Pad", status: "inactive")

      # Changeable Start
      items = Item.all.unscoped
      # Changeable End

      expect(items.count).to eq 3
    end
  end

  context "Powerball" do
    it "returns all items containing Powerball" do
      Item.create(name: "Powerball Ball")
      Item.create(name: "Powerball Goal")
      Item.create(name: "Trap Door")

      # Changeable Start
      items = Item.where("name LIKE '%Powerball%'")
      # Changeable End

      expect(items.count).to eq(2)
    end
  end

  context "Hang Tough" do
    it "returns orders for 3 users in 2 queries (aka: Remove the N+1 query)" do
      diamond  = User.create(name: "Diamond")
      turbo    = User.create(name: "Turbo")
      laser    = User.create(name: "Laser")
      ice      = User.create(name: "Ice")

      order_1 = diamond.orders.create(amount: 1)
      order_2 = turbo.orders.create(amount: 2)
      order_3 = ice.orders.create(amount: 3)
      order_4 = laser.orders.create(amount: 4)


      order_amounts = []

      # Changeable Start
      users = User.includes(:orders).first(3)
      # Changeable End

      # Use eager loading to remove the N+1 query
      # Hint: Read until section 13.1 - http://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations

      users.each do |user|
        # The problem: Each time we call user.orders, we go to the DB to pull them down.
        order_amounts << user.orders.first.amount
      end

      expect(order_amounts).to eq([1, 2, 4])
      expect(order_amounts).to_not include(3)
    end
  end

  context "The Maze" do
    it "returns all users that have placed an order" do
      gemini = User.create(name: "Gemini")
      sky    = User.create(name: "Sky")
      nitro  = User.create(name: "Nitro")

      sky.orders.create
      sky.orders.create
      nitro.orders.create

      # Changeable Start
      active_users = User.joins(:orders).distinct
      # Changeable End

      # Hint: http://guides.rubyonrails.org/active_record_querying.html#joining-tables

      expect(active_users).to eq([sky, nitro])
    end
  end

  context "Breakthrough and Conquer" do
    it "returns all orders with Footballs and Wrestling Rings" do
      wrestling_ring = Item.create(name: "Wrestling Ring")
      football       = Item.create(name: "Football")
      sweat          = Item.create(name: "Sweat")
      order_1        = Order.create(items: [wrestling_ring])
      order_2        = Order.create(items: [sweat])
      order_3        = Order.create(items: [football])

      # Changeable Start
      orders = Order.joins(:items).where("items.name = 'Wrestling Ring' OR items.name = 'Football'")
      # Changeable End

      # Hint: Take a look at the `Joins` section and the example that combines `joins` and `where` here: http://apidock.com/rails/ActiveRecord/QueryMethods/where

      expect(orders).to eq([order_1, order_3])
    end
  end

  context "The Eliminator" do
    it "returns all orders placed 2 weeks ago" do
      last_week = Date.today.last_week
      two_weeks_ago = Date.today.last_week - 7.days

      order_1 = Order.create(created_at: two_weeks_ago)
      order_2 = Order.create(created_at: Date.today)
      order_3 = Order.create(created_at: two_weeks_ago + 1.day)
      order_4 = Order.create(created_at: last_week + 1.day)
      order_5 = Order.create(created_at: two_weeks_ago + 2.days)

      # Changeable Start
      orders = Order.where("created_at < ?", Date.today.last_week)
      # Changeable End

      expect(orders).to eq([order_1, order_3, order_5])
    end
  end

  context "Atlasphere" do
    # This one is challenging.
    it "returns most popular items" do
      scoring_pod = Item.create(name: "Scoring Pod")
      lights      = Item.create(name: "Lights")
      smoke       = Item.create(name: "Smoke")

      Order.create(items: [scoring_pod, lights, smoke])
      Order.create(items: [lights, smoke, smoke])
      Order.create(items: [lights, lights, lights])

      # Changeable Start
      # items_with_count = Hash.new(0)
      #
      # Order.all.each do |order|
      #   order.items.each do |item|
      #     items_with_count[item.id] += 1
      #   end
      # end
      #
      # top_items_with_count = items_with_count.sort_by { |item_id, count|
      #   count
      # }.reverse.first(2)
      #
      # top_item_ids = top_items_with_count.first.zip(top_items_with_count.last).first
      #
      # most_popular_items = top_item_ids.map do |id|
      #   Item.find(id)
      # end
      most_popular_items = Item.joins(:orders)
                                .select('items.*, count(orders.id) AS order_count')
                                .group("items.id")
                                .order("order_count DESC")
                                .limit(2)
      # Changeable Stop

      # Hints: http://apidock.com/rails/ActiveRecord/QueryMethods/select
      #        http://stackoverflow.com/questions/8696005/rails-3-activerecord-order-by-count-on-association

      expect(most_popular_items).to eq([lights, smoke])
    end
  end
end
