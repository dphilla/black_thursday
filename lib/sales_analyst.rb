require 'csv'
require_relative '../lib/sales_engine'
require_relative '../lib/item_repository'
require_relative '../lib/merchant_repository'
require_relative 'stats'

class SalesAnalyst
  attr_reader :se

  include Stats

  def initialize(se=nil) #do we need to add an argument?
    @se = se
  end

#iteration 1

  def average_items_per_merchant #REFACTOR FIRST
    total_items = @se.items.all
    total_merchants = @se.merchants.all
    average_items = total_items.count.to_f / total_merchants.count.to_f
    average_items.round(2)
  end

  def average_items_per_merchant_standard_deviation
    info = num_items_per_merchant
    standard_deviation(info).round(2)
  end

  def merchants_with_highest_item_count
    strong_offerers = []
    bar = average_items_per_merchant+average_items_per_merchant_standard_deviation
    merch_with_num_of_items_hash.each do |key, value|
      if value > bar
        strong_offerers << key
      else
      end
    end
    strong_offerers
  end

  def average_item_price_per_merchant(id)
    merchant_prices = []
      @se.items.find_all_by_merchant_id(id).each do |x|
        merchant_prices << x.unit_price
      end
   price_avg = (merchant_prices.reduce(:+)) / merchant_prices.length
   price_avg
  end

  def average_price_per_merchant
    prices_avgs = merch_id_array.map { |id| average_item_price_per_merchant(id)}
    avg_ppm = prices_avgs.reduce(:+) / prices_avgs.length
    avg_ppm
  end

  def golden_items
    prices_avgs = merch_id_array.map { |id| average_item_price_per_merchant(id)}
    price_bar = standard_deviation(prices_avgs) * 2
    golden_items = []
    @se.items.all.each do |item|
      if item.unit_price > price_bar
        golden_items << item
      else
      end
    end
    golden_items
  end

#iteration 2

  def average_invoices_per_merchant
    info = @se.merchants.all.map {|merchant| merchant.invoices.count}
    average(info)
  end

  def average_invoices_per_merchant_standard_deviation
    info = @se.merchants.all.map {|merchant| merchant.invoices.count}
    standard_deviation(info)
  end

  def top_merchants_by_invoice_count
      info = @se.merchants.all.map {|merchant| merchant.invoices.count}
      cutoff = average(info) + (standard_deviation(info) * 2)
      @se.merchants.all.find_all {|merchant| merchant.invoices.length > cutoff}
  end

  def bottom_merchants_by_invoice_count
      info = @se.merchants.all.map {|merchant| merchant.invoices.count}
      cutoff = average(info) - (standard_deviation(info) * 2)
      @se.merchants.all.find_all {|merchant| merchant.invoices.length < cutoff}
  end

  def top_days_by_invoice_count #break out to stats module
        top_days_via_invoices
  end

  def invoice_status(status)
    if status == :pending
      pending_invoices
    elsif status == :shipped
      shipped_invoices
    elsif status == :returned
      returned_invoices
    else
      "thats not an option for invoice status"
    end
  end

  #iteration 4

  def total_revenue_by_date(date)
    invoices = invoices_by_date_hash[date]
    invoices = invoices.map do |invoice_item_id|
      invoice_i = @se.invoice_items.find_by_id(invoice_item_id)
      invoice_i.unit_price.to_i * invoice_i.quantity
    end
    invoices.reduce(:+)
  end

  def top_revenue_earners(x) #stuck here
    # brings in top x revenue earners, if no argument is given, just returns
    # top 20 revenue earners in an array
      top_earners = []
      revenue_sorted_from_most_down  =  merchant_ids_to_revenue_hash.keys.sort.reverse
      x_revenues = revenue_sorted_from_most_down[0..(x-1)]
      x_revenues.each do |revenue|
      top_earners <<  merchant_ids_to_revenue_hash.key(revenue)
      end
    top_earners.map { |merchant_id|  @se.merchants.find_by_id(merchant_id)}
      top_earners

    #returns ordered array by revenue (largest to small)
  end

  def merchants_with_pending_invoices
    #which merchants have pending invoices
        #an invoice is considered pending if none of its transactions are
        # succesful
  end

  def merchants_with_only_one_item
    #ret array
  end

  def merchants_with_only_one_item_registered_in_month
    #merchants that only sell one item by the time they registered
  end

  def revenue_by_merchant(merchant_id)
    #finds total revenue for a single merchant
  end

  def most_sold_item_for_merchant(merchant_id)
    # returns item in array with highest quantity sold, or if ties between items, returns tying items
    #in an array
  end

  def best_item_for_merchant(merchant_id)
    #which item sold is best in terms of revenue generated
  end



end


se = SalesEngine.from_csv({ :items   => "./data/items.csv",
                            :merchants => "./data/merchants.csv",
                            :invoices => "./data/invoices.csv",
                            :invoice_items => "./data/invoice_items.csv",
                            :transactions => "./data/transactions.csv",
                            :customers => "./data/customers.csv"})

sa = SalesAnalyst.new(se)
require 'pry';binding.pry
